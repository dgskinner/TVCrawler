# TVCrawler

This is a web crawler written in Ruby. It goes through each TV show on Wikipedia’s list of TV shows 
(http://en.wikipedia.org/wiki/List_of_television_programs_by_name) and fetches metadata from each page. 
If fetched successfully, a JSON file containing the show's metadata is created. In order to avoid exceeding 
Wikipedia’s rate limit, a random timer between 0 and 2 seconds is set between each fetch. 

To run: In the command line, navigate to the ‘json_files’ directory. Type the command ‘ruby ../crawler.rb’ 
to run the crawler. This will generate the new files in the ‘json_files’ folder.
