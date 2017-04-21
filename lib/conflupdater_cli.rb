# frozen_string_literal: true
require 'pp'
require 'thor'
require 'config'
require 'json'
require 'highline'
require 'pathname'
require 'pry'

require_relative 'taghosts'
require_relative 'confluence_api'
require_relative 'pages_display'

Signal.trap("INT"){
  puts "Interrupt.  Exiting."
  exit
}

class ConflupdaterCLI < Thor
  APP_ROOT = Pathname.new File.expand_path('../../',  __FILE__)

  desc "taghosts", "Update taghosts inventory page."
  def taghosts
    configure unless configured?

    # Obtain current version of page
    con = ConfluenceApi.new(base_url: Settings.base_url, user: Settings.user, pass: Settings.pass) 
    version = con.page_version(page_title: Settings.page_title, space_key: Settings.space_key)

    # Update content of page
    taghosts = Taghosts.new(page_id: Settings.page_id,
                            space_key: Settings.space_key,
                            page_version: version,
                            source: Settings.source_file)
    update_data = taghosts.page_update
    puts update_data.to_json
  end

  desc "vulnscan", "Add or update vulnscan report."
  def vulnscan
    configure unless configured?

    # Check if page exists
    # Obtain Page metadata
    # Get body content
    # Update/Create Page

    puts "Not implemented."
  end

  desc "pages", "List pages in configured space."
  def pages
    configure unless configured?
    user, pass = prompt_for_credentials

    con = ConfluenceApi.new(base_url: Settings.base_url, user: user, pass: pass) 
    resp = con.pages_in_space(space_key: Settings.space_key)

    pages = PagesDisplay.new(resp)

    puts pages.to_s
  end

  desc "print", "Print configuration."
  def print
    configure unless configured?
    pp Settings.to_h
  end

  ## Non-task functions 
  private 

  def configured?
    defined?(Settings) ? true : false
  end

  def configure
    config_file = File.join(APP_ROOT,'config/conflupdater.yml')
    unless File.exist? config_file
      puts "Unable to read config: #{config_file}"
      exit
    end

    Config.load_and_set_settings(config_file)
  end
  
  # get user & pass
  def prompt_for_credentials
    cli = HighLine.new
    user = cli.ask("Enter Username:")
    pass = cli.ask("Enter Password:") { |q| q.echo = "*" }
    return [user, pass]
  end

end

