class Rack::Attack
  ### Throttle Requests to Prevent Abuse ###
  throttle('req/ip', limit: 5, period: 1.second) do |req|
    req.ip
  end

  safelist('allow stripe webhook') do |req|
    req.path == '/stripe/webhook' && req.post?
  end

    # Safelist Health Check Route
    safelist('allow health check') do |req|
      req.path == '/okcomputer' && req.get?
    end

  ### Block Requests with Invalid MIME Types ###
  blocklist('block invalid mime type') do |req|
    req.media_type == "/"
  end

  # Block SQL injection patterns
  blocklist('block SQL injection patterns') do |req|
    req.query_string =~ /(\%27)|(\')|(\-\-)|(\%23)|(#)/i ||
    req.query_string =~ /(\%22)|(\")|(\%3B)|(;)/i ||
    req.query_string =~ /(\%7C)|(\|)/i ||
    req.query_string =~ /(\%26)|(&)/i ||
    req.query_string.include?('UNION SELECT') ||
    req.query_string.include?('SELECT * FROM') ||
    req.query_string.include?('SELECT COUNT(') ||
    req.query_string.include?('SELECT ') ||
    req.query_string.include?('DROP TABLE') ||
    req.query_string.include?('INSERT INTO') ||
    req.query_string.include?('xp_cmdshell')
  end

  # Block common Local File Inclusion (LFI) and Remote File Inclusion (RFI) patterns
  blocklist('block LFI/RFI patterns') do |req|
    req.path =~ /(\.\.\/|\.\.\\)/i ||  # Directory traversal patterns
    req.path.include?('/etc/passwd') ||
    req.path.include?('boot.ini') ||
    req.path.include?('web.config') ||
    req.path.include?('proc/self/environ') ||
    req.path.include?('var/log') ||
    req.query_string.include?('http://') ||  # Attempting to load remote files
    req.query_string.include?('https://') ||
    req.query_string.include?('/etc/shadow') ||
    req.query_string.include?('/bin/bash') ||
    req.query_string.include?('php://input') ||  # PHP input stream
    req.query_string.include?('data://text') ||  # Data URI scheme
    req.query_string.include?('expect://') ||  # PHP expect module
    req.query_string.include?('php://filter') ||  # PHP filter module
    req.query_string.include?('php://wrapper')  # PHP wrapper
  end

  # Block attempts to access sensitive files
  blocklist('block sensitive files access') do |req|
    req.path.include?('.env') ||  # Environment files
    req.path.include?('.git') ||  # Git directories
    req.path.include?('.htaccess') ||  # Apache configuration files
    req.path.include?('.htpasswd') ||  # Apache password files
    req.path.include?('.DS_Store') ||  # MacOS metadata files
    req.path.include?('id_rsa') ||  # SSH private key files
    req.path.include?('.ssh') ||  # SSH directory
    req.path.include?('wp-config.php') ||  # WordPress config files
    req.path.include?('xmlrpc.php') ||  # WordPress XML-RPC API
    req.path.include?('composer.json') ||  # PHP Composer files
    req.path.include?('yarn.lock')  # Yarn package manager files
  end

  # Block XSS attack patterns
  blocklist('block XSS patterns') do |req|
    req.query_string =~ /<script.*?>/i ||  # Script tags
    req.query_string =~ /<img.*?src=/i ||  # Image tags with src
    req.query_string =~ /onerror\s*=\s*/i ||  # JavaScript error handlers
    req.query_string =~ /<iframe.*?>/i ||  # Iframe tags
    req.query_string =~ /javascript:/i ||  # JavaScript URI scheme
    req.query_string =~ /vbscript:/i ||  # VBScript URI scheme
    req.query_string =~ /expression\(/i ||  # CSS expressions
    req.query_string =~ /alert\(/i ||  # JavaScript alert function
    req.query_string =~ /confirm\(/i ||  # JavaScript confirm function
    req.query_string =~ /prompt\(/i  # JavaScript prompt function
  end

  # Block SSRF attack patterns (Server-Side Request Forgery)
  blocklist('block SSRF patterns') do |req|
    req.query_string.include?('169.254.169.254') ||  # AWS metadata service
    req.query_string.include?('localhost') ||  # Localhost
    req.query_string.include?('127.0.0.1') ||  # Loopback IP
    req.query_string.include?('::1') ||  # IPv6 loopback
    req.query_string.include?('0.0.0.0') ||  # INADDR_ANY
    req.query_string.include?('metadata.google.internal')  # Google Cloud metadata service
  end

  ### Throttle Logins to Prevent Brute-Force Attacks ###
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.params['email'].presence
    end
  end

  ### Block Requests with a Missing or Invalid User-Agent Header ###
  blocklist('block missing User-Agent') do |req|
    req.user_agent.nil? || req.user_agent.empty?
  end

  ### Track and Monitor Suspicious Activity ###
  track('track suspicious requests') do |req|
    req.path.include?('admin') && req.get?
  end

  ### Custom Response for Blocked Requests ###
  self.blocklisted_responder = lambda do |env|
    [ 403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
  end

  ### Optional: Log the Tracked Requests ###
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    message = "[Rack::Attack] #{payload.inspect}"
    # Might be slow so change to a background job if we need to keep this for a long time
    Notifications::SlackNotifier.call(message: message, channel: :errors)
  end
end
