module CCCB::Core::Help
  extend Module::Requirements
 
  def add_help feature, topic, summary, text, special = :none
    help.topics[ topic ] = {
      :feature => feature,
      :summary => summary,
      :text => text,
      :special => special
    }
  end

  def module_load
    help.topics = {}

    add_request( :debug, /^loglevel (?<level>\w+)/i ) do |match, message|
      if message.user.superuser?
        level = match[:level].to_s.upcase.to_sym
        if self.class.constants.include? level
          logging.loglevel = self.class.const_get( level )
          "Okay, logging is now set to #{level}"
        else
          "No such log level #{level}"
        end
      else
        "Denied"
      end
    end

    add_request( :help, /^h[ae]lp!?(?:\s+(?<topic>\w+))?$/i ) do |match, message|
      "See #{CCCB.instance.get_setting("http_server","url")}/network/#{message.network}/help/#{match[:topic]}"
    end

    add_help(
      :help,
      "cccb8",
      "What is cccb8?",
      [ 
        "cccb8 is an IRC bot written in Ruby by ccooke.",
        "It is currently at version #{CCCB::VERSION}"
      ],
      :info
    )
    add_help(
      :help,
      "requests",
      "Making requests of the bot",
      [
        "When making a request in a channel, always prefix",
        "the name of the bot - for instance: ",
        "<user> #{nick}: one or two?",
        "If you are in a query with the bot, you need no prefix."
      ],
      :info
    )

    add_help(
      :help,
      "reload",
      "Reloading the bot",
      [
        "Sending the bot a CTCP RELOAD command causes it",
        "to halt all action, unload all files and plugins",
        "and reload itself entirely."
      ],
      :superuser
    )

    CCCB::ContentServer.add_keyword_path('help') do |network,session,match|
      features = network.get_setting("allowed_features")
      url = "/help/"
      local_topics = if network
        url = "/network/#{network.name}/help/"
        local_topics = help.topics.each_with_object({}) do |(name,topic),hash| 
          hash[name] = topic if features.include? topic[:feature].to_s
        end
      else
        help.topics
      end

      if match[:call] and local_topics.include? match[:call]
        {
          title: "Help topic: #{match[:call]}",
          blocks: [
            [ :content, 
              local_topics[match[:call].to_s][:text].map { |line|
                line = CGI::escapeHTML(line)
                line.split(/\s+/).map { |word|
                  if local_topics.include? word
                    "<a href=\"#{url}#{word}\">#{word}</a>"
                  else
                    word
                  end
                }.join(" ")
              }.join("<br/>")
            ],
            [ :nav, "Return to <a href=\"#{url}\">index</a>" ],
          ]
        }
      else
        {
          title: "Index of help pages",
          template: :help_index,
          topics: local_topics
        }
      end
    end
  end
end
