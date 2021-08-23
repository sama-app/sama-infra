provider "aws" {
  profile = "default"
  region  = local.region
}

resource "aws_cloudfront_distribution" "sama_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [local.env.fqdn, local.env.legacy_fqdn]
  price_class         = "PriceClass_200"

  // S3 origin for app.meetsama.com/*
  origin {
    domain_name = data.aws_s3_bucket.sama_web.bucket_regional_domain_name
    origin_id   = local.sama_web_origin_id

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${local.env.sama_web_s3_origin_identity}"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS"]
    cached_methods   = ["HEAD", "GET", "OPTIONS"]
    target_origin_id = local.sama_web_origin_id

    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.sama_web.id

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = "arn:aws:lambda:us-east-1:216862985054:function:cloudfront-s3-error-redirect:8"
      include_body = false
    }
  }

  custom_error_response {
    error_caching_min_ttl = 1 # CF does not cache 416 responses
    error_code            = 416
    response_code         = 200
    response_page_path    = "/index.html"
  }

  // ALB origin for app.meetsama.com/api/*
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    domain_name = data.aws_alb.sama_service.dns_name
    origin_id   = local.sama_service_origin_id
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.sama_service_origin_id

    cache_policy_id          = data.aws_cloudfront_cache_policy.no_cache.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    viewer_protocol_policy   = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = data.aws_cloudfront_function.add_real_client_ip.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = local.env.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  tags = local.tags
}

resource "aws_cloudfront_cache_policy" "sama_web" {
  name        = "sama-web-policy-${terraform.workspace}"
  default_ttl = 31536000
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

data "aws_s3_bucket" "sama_web" {
  bucket = local.env.fqdn
}

data "aws_alb" "sama_service" {
  name = "alb-${terraform.workspace}"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_cache_policy" "no_cache" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_function" "add_real_client_ip" {
  name = "add-real-client-ip"
  stage = "LIVE"
}