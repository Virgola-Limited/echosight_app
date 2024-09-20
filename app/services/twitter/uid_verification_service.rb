require 'nokogiri'
require 'open-uri'

module Twitter
  class UidVerificationService
    MAX_RETRIES = 3
    RETRY_SLEEP_INTERVAL = 5

    def initialize
      @incorrect_uids = []
    end

    def call
      fetch_and_verify_uids
      print_report
    end

    private

    def fetch_and_verify_uids
      Identity.find_in_batches(batch_size: 1000) do |identities|
        identities.each do |identity|
          retry_count = 0
          begin
            if incorrect_uid?(identity.handle, identity.uid)
              @incorrect_uids << { handle: identity.handle, current_uid: identity.uid }
            end
          rescue Net::OpenTimeout, Net::ReadTimeout => e
            Rails.logger.error "Timeout error for handle #{identity.handle}: #{e.message}"
            retry_count += 1
            if retry_count <= MAX_RETRIES
              sleep RETRY_SLEEP_INTERVAL
              retry
            end
          rescue StandardError => e
            Rails.logger.error "Error fetching UID for handle #{identity.handle}: #{e.message}"
          end
        end
      end
    end

    def incorrect_uid?(handle, current_uid)
      correct_uid = fetch_correct_uid_from_twitter(handle)
      correct_uid && correct_uid != current_uid
    end

    def fetch_correct_uid_from_twitter(handle)
      url = "https://twitter.com/#{handle}"
      p "Fetching UID for handle: #{handle}"
      doc = Nokogiri::HTML(URI.open(url))
      script_tag = doc.at('script:contains("profile_id")')
      if script_tag
        match = script_tag.text.match(/"profile_id":"(\d+)"/)
        return match[1] if match
      end
      nil
    rescue StandardError => e
      Rails.logger.error "Error fetching UID for handle #{handle}: #{e.message}"
      nil
    end

    def print_report
      puts "Incorrect UIDs report:"
      @incorrect_uids.each do |record|
        puts "Handle: #{record[:handle]}, Current UID: #{record[:current_uid]}"
      end
    end
  end
end
