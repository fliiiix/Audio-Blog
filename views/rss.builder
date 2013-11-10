xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{title}"
    xml.description "#{description}"
    xml.link "#{baseUrl}"

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link "#{baseUrl}/#{post.url.nice}"
        xml.description post.title
        xml.pubDate Time.parse(post.created_at.to_s).rfc822()
        xml.guid "#{baseUrl}/id/#{post.id}"
      end
    end
  end
end