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

  it 'sends a Slack message if a queue size exceeds the threshold' do
    message = "The #{queue_name} queue has reached a size of #{queue_size}"
    expect(Notifications::SlackNotifier).to receive(:call).with(message: message, channel: :errors)

    described_class.new.perform
  end

  it 'does not send a Slack message if all queue sizes are below the threshold' do
    allow(Sidekiq::Queue).to receive(:all).and_return([double('queue', name: queue_name, size: 19)])

    expect(Notifications::SlackNotifier).not_to receive(:call)

    described_class.new.perform
  end
end
