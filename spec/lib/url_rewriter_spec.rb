require 'rails_helper'

RSpec.describe UrlRewriter do
  let(:text_with_urls) { "Check out this link: http://example.com/home" }
  let(:text_with_invalid_urls) { "Check out this link: http://invalidurl" }
  let(:rewriter) { described_class.new(text) }

  describe '#call', vcr: true do
    context 'when URL resolves successfully' do
      let(:text) { text_with_urls }

      it 'replaces the URL with the resolved URL', vcr: { cassette_name: 'successful_url_resolution' } do
        VCR.use_cassette('successful_url_resolution') do
          expect(rewriter.call).to eq("Check out this link: http://example.com/home")
        end
      end
    end

    context 'when URL does not resolve' do
      let(:text) { text_with_invalid_urls }

      it 'keeps the original URL', vcr: { cassette_name: 'unsuccessful_url_resolution' } do
        VCR.use_cassette('unsuccessful_url_resolution') do
          expect(rewriter.call).to eq("Check out this link: http://invalidurl")
        end
      end
    end
  end
end
