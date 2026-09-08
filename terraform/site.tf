# Bucket privado para el contenido estatico del portfolio.
# Separado del bucket de estado (s3.tf) a proposito: este va a tener una
# bucket policy que le da lectura a CloudFront, el de estado se queda sellado.
resource "aws_s3_bucket" "site" {
  bucket = "portfolio-devops-site" # tiene que ser un nombre unico a nivel S3 global, ajustalo si esta tomado
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = false # la policy de mas abajo (scoped al OAC) tiene que poder aplicarse
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Certificado TLS ---
# Obligatoriamente en us-east-1: es la unica region que CloudFront lee para
# certificados, sin importar la region del resto del stack (ver provider.tf).
resource "aws_acm_certificate" "site" {
  provider          = aws.us_east_1
  domain_name       = "landriel.site"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Como el DNS de landriel.site vive en Cloudflare (no Route53), la validacion
# no se puede automatizar sola: este output te da el registro CNAME exacto
# que hay que crear a mano en el dashboard de Cloudflare para probar que sos
# dueno del dominio.
output "acm_validation_record" {
  value = {
    name  = tolist(aws_acm_certificate.site.domain_validation_options)[0].resource_record_name
    type  = tolist(aws_acm_certificate.site.domain_validation_options)[0].resource_record_type
    value = tolist(aws_acm_certificate.site.domain_validation_options)[0].resource_record_value
  }
}

# --- Origin Access Control ---
# El "candado": CloudFront firma sus pedidos al bucket con SigV4, y la bucket
# policy de mas abajo solo acepta pedidos firmados por ESTA distribucion.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "portfolio-site-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- Distribucion de CloudFront ---
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["landriel.site"]
  price_class         = "PriceClass_100" # US/Europa alcanza, no hace falta cobertura global

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "portfolio-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "portfolio-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    cache_policy_id         = "658327ea-f89d-4fab-a63d-7e88639e58f6" # managed policy "CachingOptimized"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# --- Bucket policy: solo esta distribucion puede leer el bucket ---
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
        }
      }
    }]
  })
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.site.domain_name
}
