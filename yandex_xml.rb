#!/usr/local/bin/ruby
require 'net/http'
require 'rexml/document'
require 'colorize'
require 'terminal-table'
require 'cgi'

#See http://api.yandex.ru/xml/doc/dg/task/registration.xml
HOST = 'xmlsearch.yandex.com'
PATH = '/xmlsearch'
USER = 'USER'
KEY ='KEY'

BHR = '='.light_black * 150
HR = ('-' * 150).light_black
TAB = ' ' * 4

########################################################################
def search(search_query)

  print "\e[H\e[2J#{BHR}\nSearch query: #{search_query.light_yellow}\n"

  search_query = URI.encode search_query

  Net::HTTP.start(HOST) do |http|

    query = "user=#{USER}&key=#{KEY}&l10n=en&query=#{search_query}"

    uri = URI::HTTP.build [nil, HOST, nil, PATH, query, nil]

    print "\n#{HOST.light_blue} >>> "

    start_time = Time.now
    response = http.get uri
    execution_time = (Time.now - start_time) * 1000

    puts " #{response.code} #{response.message} (#{execution_time.round(2)} ms)\n".yellow

    raise 'Bad status code!' unless response.code.to_i == 200

    xml = REXML::Document.new(response.body)

    if error = xml.elements['//error']
      raise 'Yandex XML: ' + error.text
    end

    # Fixed spelling.
    if reask = xml.elements['//reask']
      source_text = reask.elements['source-text'].to_s.gsub(/<hlword>(.*?)<\/hlword>/u, '\1'.yellow).gsub(/<[^>]*>/ui,'')
      puts "#{source_text} -> #{reask.elements['text-to-show'].text}\n\n"
    end

    puts 'Y'.light_red + 'ndex: ' + xml.elements['//found-human'].text

    xml.elements.each_with_index("//results//group") do |group, position|
      puts HR
      doc = group.elements['doc']

      title = "##{position + 1}".ljust(4).green.bold
      title << doc.elements['title'].to_s.gsub(/<[^>]*>/ui,'').green if doc.elements['title'].text
      puts title
      if passage = doc.elements['passages/passage']
        passage = passage.to_s.gsub(/<hlword>(.*?)<\/hlword>/u, '\1'.light_yellow).gsub(/<[^>]*>/ui,'')
        puts TAB + CGI.unescapeHTML(passage)
      end
      puts TAB + doc.elements['url'].text.light_blue
    end
      puts "#{HR}\n\nQuery link: #{('http://yandex.ru/yandsearch?text=' + search_query).light_blue}\n\n"
  end

end

########################################################################
user_response = nil
until user_response == "\e"

  if user_response && user_response != ""
    begin
      search user_response
    rescue Exception => e
      puts $!.to_s.red
      exit;
    end
  end
  
  puts BHR
  print 'Search query: '
  user_response = ARGV[0] && !user_response ? ARGV[0] : $stdin.gets.chomp

end
