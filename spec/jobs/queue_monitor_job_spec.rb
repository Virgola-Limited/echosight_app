require 'rails_helper'

RSpec.describe QueueMonitorJob, type: :job do
  let(:queue_name) { 'default' }
  let(:queue_size) { 91 }
  let(:scheduled_size) { 299 }

  before do
    Sidekiq::Testing.fake!  # Use fake mode for testing
  end

  after do
    # Reset the stubs after each test to avoid interference
    allow(Sidekiq::Queue).to receive(:all).and_call_original
    allow(Sidekiq::ScheduledSet).to receive(:new).and_call_original
  end

  it 'sends a Slack message if a queue size exceeds the threshold' do
    allow(Sidekiq::Queue).to receive(:all).and_return([double('queue', name: queue_name, size: queue_size)])
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return(double('scheduled_set', size: 500))

    message = "The #{queue_name} queue has reached a size of #{queue_size}"
    expect(Notifications::SlackNotifier).to receive(:call).with(message: message, channel: :errors)

    described_class.new.perform
  end

  it 'does not send a Slack message if all queue sizes are below the threshold' do
    allow(Sidekiq::Queue).to receive(:all).and_return([double('queue', name: queue_name, size: 19)])
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return(double('scheduled_set', size: 500))

    expect(Notifications::SlackNotifier).not_to receive(:call)

    described_class.new.perform
  end

  it 'sends a Slack message if the scheduled queue size drops below the threshold' do
    allow(Sidekiq::Queue).to receive(:all).and_return([double('queue', name: queue_name, size: 19)])
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return(double('scheduled_set', size: scheduled_size))

    message = "The scheduled queue has dropped below 500 with a size of #{scheduled_size}"
    expect(Notifications::SlackNotifier).to receive(:call).with(message: message, channel: :errors)

    described_class.new.perform
  end

  it 'does not send a Slack message if the scheduled queue size is above the threshold' do
    allow(Sidekiq::Queue).to receive(:all).and_return([double('queue', name: queue_name, size: 19)])
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return(double('scheduled_set', size: 500))

    expect(Notifications::SlackNotifier).not_to receive(:call)

    described_class.new.perform
  end
end
