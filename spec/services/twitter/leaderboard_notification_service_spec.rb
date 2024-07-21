require 'rails_helper'

RSpec.describe String do
  subject { described_class.new }

  it { expect(1).to eql(1) }
end
