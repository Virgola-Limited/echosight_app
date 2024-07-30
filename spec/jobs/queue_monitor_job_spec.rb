# spec/jobs/queue_monitor_job_spec.rb
require 'rails_helper'

RSpec.describe QueueMonitorJob, type: :job do
  let(:queue_name) { 'default' }
  let(:queue_size) { 31 }

  before do
    Sidekiq::Testing.fake!  # Use fake mode for testing

    # Mock the Sidekiq queues
    allow(Sidekiq::Queue).to receive(:all).and_return([double('queue', name: queue_name, size: queue_size)])
  end

  it 'sends an email if a queue size exceeds the threshold' do
    expect(QueueMailer).to receive(:queue_size_alert).with(queue_name, queue_size).and_return(double(deliver_now: true))

    described_class.new.perform
  end

  it 'does not send an email if all queue sizes are below the threshold' do
    allow(Sidekiq::Queue).to receive(:all).and_return([double('queue', name: queue_name, size: 19)])

    expect(QueueMailer).not_to receive(:queue_size_alert)

    described_class.new.perform
  end
end
