require 'open-uri'

module YumS3Sync
class HTTPDownloader
  def initialize(baseurl)
    @baseurl = baseurl
  end

  def download(relative_url)
    retries = 0

    url = "#{@baseurl}/#{relative_url}"
    puts "Downloading #{url}"

    begin
      open("#{url}")
    rescue OpenURI::HTTPError => e
      if e.io.status[0] == "404"
        fail "File #{url} does not exist 404"
      end

      raise e
    rescue SocketError => e
      if retries < 10
        retries += 1
        puts "Error downloading #{url} : #{e.message} retry ##{retries}"
        sleep(1)
        retry
      else
        puts "Error downloading #{url} : #{e.message}"
        raise e
      end
    end
  end
end
end
