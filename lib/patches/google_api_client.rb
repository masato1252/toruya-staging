# frozen_string_literal: true

# XXX: ruby after 2.5 don't allow don't support multiline headers, that break google-api-client https://github.com/googleapis/google-api-ruby-client/pull/648
# But google_contacts_api only support google_api_client 0.8.6, so fix the header by this patch
module Google
  class APIClient
    module ENV
      remove_const(:OS_VERSION) if (defined?(OS_VERSION))

      OS_VERSION = begin
        if RUBY_PLATFORM =~ /mswin|win32|mingw|bccwin|cygwin/
          # Confirm that all of these Windows environments actually have access
          # to the `ver` command.
          `ver`.sub(/\s*\[Version\s*/, '/').sub(']', '').strip
        elsif RUBY_PLATFORM =~ /darwin/i
          "Mac OS X/#{`sw_vers -productVersion`}"
        elsif RUBY_PLATFORM == 'java'
          # Get the information from java system properties to avoid spawning a
          # sub-process, which is not friendly in some contexts (web servers).
          require 'java'
          name = java.lang.System.getProperty('os.name')
          version = java.lang.System.getProperty('os.version')
          "#{name}/#{version}"
        else
          `uname -sr`.sub(' ', '/')
        end
      rescue Exception
        RUBY_PLATFORM
      end.strip
    end
  end
end

