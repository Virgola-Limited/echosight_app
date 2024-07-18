class TestimonialsComponent < ApplicationComponent
  def initialize
    @testimonials = [
      {
        title: 'Thanks for the early access!',
        quote: 'Thanks, <a href="https://x.com/loftwah" target="_blank">@loftwah</a>, for giving me the early access. Really love this service...',
        author: '@TimoCodes',
        author_link: 'https://x.com/TimoCodes/status/1795403171399119042'
      },
      {
        title: 'Getting harder to get insights.',
        quote: 'Everyday it\'s getting harder and harder to get insights. Echosight helps! <a href="https://x.com/imaCoden/status/1802930070526312513" target="_blank">Check it out</a>',
        author: '@imaCoden',
        author_link: 'https://x.com/imaCoden/status/1802930070526312513'
      },
    ]
  end
end
