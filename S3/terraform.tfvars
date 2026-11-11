#################################
# AWS
#################################

region = "ap-southeast-2"

#################################
# Bucket
#################################

bucket_name = "s3-static-website-novartis"

environment = "POC"

project = "NOVARTIS"

application = "S3"

owner = "SHANKAR"

cost_center = "0000"

additional_tags = {}


#################################
# Encryption
#################################

#################################
# Default Encryption
#################################
/*
encryption_type = "aws:kms"

kms_key_type = "AWS_MANAGED"
*/
bucket_key_enabled = true

#################################
# Versioning
#################################

enable_versioning = true


#################################
# Ownership
#################################

object_ownership = "BucketOwnerEnforced"


#################################
# Public Access
#################################

block_public_acls       = true
ignore_public_acls      = true
block_public_policy     = true
restrict_public_buckets = true

#################################
# Static Website Hosting
#################################

static_website_type = "website"

#################################
# Static Website Hosting
#################################

website_index_document = "index.html"

website_error_document = null

#################################
# Static Website Hosting
#################################

redirect_host_name = null

redirect_protocol = null



#################################
# Notifications
#################################

enable_event_notifications = false

enable_eventbridge_notifications = false

#################################
# Transfer Acceleration
#################################

enable_transfer_acceleration = false


#################################
# Requester Pays
#################################

enable_requester_pays = false


#################################
# Object Lock
#################################

enable_object_lock = false

object_lock_mode = null

object_lock_days = null
