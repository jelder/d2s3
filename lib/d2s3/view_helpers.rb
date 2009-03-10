require 'base64'

module D2S3
  module ViewHelpers
    include D2S3::Signature

    def s3_http_upload_tag(options = {})
      bucket          = D2S3::S3Config.bucket
      access_key_id   = D2S3::S3Config.access_key_id
      key             = options[:key] || ''
      content_type    = options[:content_type] || '' # Defaults to binary/octet-stream if blank
      redirect        = options[:redirect] || '/'
      acl             = options[:acl] || 'public-read'
      expiration_date = 1.hours.from_now.strftime('%Y-%m-%dT%H:%M:%S.000Z')

      policy = Base64.encode64(
        "{'expiration': '#{expiration_date}',
          'conditions': [
            {'bucket': '#{bucket}'},
            ['starts-with', '$key', '#{key}'],
            {'acl': '#{acl}'},
            {'success_action_redirect': '#{redirect}'},
            ['starts-with', '#{content_type}', ''],
            ['content-length-range', 0, 1048576]
          ]
        }").gsub(/\n|\r/, '')

        signature = b64_hmac_sha1(D2S3::S3Config.secret_access_key, policy)

        out = ""
        out << %(
          <form action="https://#{bucket}.s3.amazonaws.com/" method="post" enctype="multipart/form-data">
          <input type="hidden" name="key" value="#{key}/${filename}">
          <input type="hidden" name="AWSAccessKeyId" value="#{access_key_id}">
          <input type="hidden" name="acl" value="#{acl}">
          <input type="hidden" name="success_action_redirect" value="#{redirect}">
          <input type="hidden" name="policy" value="#{policy}">
          <input type="hidden" name="signature" value="#{signature}">
          File to upload to S3:
          <input name="file" type="file">
          <br>
          <input type="submit" value="Upload File to S3">
          </form>
        )
      end
    end
  end

  ActionView::Base.send(:include, D2S3::ViewHelpers)