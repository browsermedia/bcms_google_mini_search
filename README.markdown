# Google Mini Search Module

This module allows BrowserCMS to integrate with a Google Mini Search Appliance. Google Mini is a standalone search
server, which can be configured to crawl your website. This module submits queries to a Mini server, and formats the results.
It consists of the following two portlets.

1. Search Box - Displays an input box that submits a search query.
2. Google Mini Search Results Portlet - Sends query to the Mini, formats the XML response and displays the results.

Note: This module assume the BrowserCMS web site owner has access to their own Google Mini server, either hosted by
themselves or a third party service.

## A. Instructions
There are two basic steps to setting up this module:

1. Configure your Google Mini to crawl your site.
2. Install the module and configure it to point to your Google Mini server.

These instructions assume the Mini is already set up and running.

### B. Configuring Google Mini
Configuring the mini include three basic steps, configuring it to crawl your site, creating a collection which limits
what is returned to just your site, and creating a front end, which allows you to submit search queries.

#### B.1. Configuring the crawler
1. Log into your search appliance (i.e. http://google.mini.mysite.com), and enter your account username/password.
2. Click on the 'Crawl and Index' link in the left navigation.
3. In the top box 'Start Crawling from the Following URLs:' add a new line with the full domain name of your site. (i.e. http://www.mysite.com)
4. In the bottom box, 'Follow and Crawl Only URLs with the Following Patterns:', enter a pattern of urls you want to crawl. (i.e. www.mysite.com/)
5. Click 'Save URLs to Crawl button'

Once the crawler is configured, it may take 15+ minutes for it to crawl your site. You can still finish configuring
the mini, but you may need to wait to test the results.

#### B.2. Configuring the collection
1. Click the collections link in the left nav. This will allow use a create a search collection specifically for this site.
2. Type the name of the new collection into the 'Collection Name' text box, and click 'Create Collection' (i.e. MYSITE).
3. After the page refreshes, click the 'Edit' link to the right of the new collection.
4. In the top box, 'Include Content Matching the Following Patterns:', enter the same pattern as step B.1.3 above (i.e. http://www.mysite.com/)
5. Click 'Save Collection Defination'

#### B.3. Configuring the front end
1. In the left nav, click the 'Serving' link
2. In the 'Front End Name' text field, enter the name for your front end. (i.e. MYSITE_frontend.)
3. Click 'Create Front End' to save it.

At this point, you should have the Google Mini appliance configured. If you want to test out the search results using
the Mini's default search UI, you can click the 'Test Center' link in the upper right hand corner. Select your new
collection and front end by name, and submit queries.

### C. Configuring the BrowserCMS Google Mini Search Module
These instructions assume you have successfully installed the bcms_google_mini_search module into your project. To make
the module work, you will have to configure two portlets.

1. In your sitemap, create a new section called 'Search', with a path '/search'.
2. Create a page called 'Search Results', with a path '/search/search-results'.
3. On that page, add a new 'Google Mini Search Engine' portlet. Keep the default for most fields.
4. In the Service URL, field, enter in the domain name to your google mini server (i.e.  http://google.mini.mysite.com). Note: This URL should be just the domain, i.e. no /search.
5. In the Collection Name field, enter the same name you gave your collection in B.2.2. (i.e. MYSITE)
6. In the Front End Name field, enter the same name you have your frontend in B.3.2 (i.e. MYSITE_frontend)
7. Make sure the 'path' attribute is the same as the page you are adding  the portlet to (i.e. /search/search-results
8. Save the portlet
9. On another page create a Search Box portlet (alternatively, you can create the portlet and add it your templates via render_portlet)
10. Set the 'Search Engine Name' field to the exact same name as the portlet in step C.3 above (i.e. Google Mini Search Engine)
11. Save the portlet

At this point, you can test the search by entering in a term to the Search Box portlet. If its working, it should call
the Search Results page and display the same results as what you see in the Mini 'Test Center'. You can style the HTML in
the template to tweak how your search results will work.