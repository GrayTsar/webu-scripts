local novelTitleElement = 'h1.novel-title.text2row'
local novelImageUrlElement = 'div.fixed-img'
local novelDescriptionElement = 'div.summary'
local novelAuthorElement = 'span.author'
local novelGenresElement = 'div.categories'
local novelTagsElement = 'div.tags'
local novelStatusElement = 'div.header-stats'
local novelStatusContentElement = 'div.summary-content'
local chapterListElement = 'li.wp-manga-chapter'
local searchNovelsElement = 'div.c-tabs-item__content'
local chapterTextElement = 'div.c-blog-post'

local ajaxChapterRelativeUrl = 'ajax/chapters/'

function getChapterText(url)
	local document = lib:getDocument(url)
	local textDocument = document:selectFirst('div#chapter-container'):select('p')

	return textDocument:toString()
end

function search(searchQuery)
    local tokenValue = lib:getDocument('https://www.lightnovelpub.com/search'):selectFirst('form#novelSearchForm'):child(1):attr('value')
    local body = lib:getFormBuilder():addFormDataPart('inputContent', searchQuery):build()
    local request = lib:getRequestBuilder():url('https://www.lightnovelpub.com/lnsearchlive'):addHeader("accept", "*/*"):addHeader("content-length", "16"):addHeader("content-type", "application/x-www-form-urlencoded; charset=UTF-8"):addHeader("lnrequestverifytoken", tokenValue):addHeader("referer", "https://www.lightnovelpub.com/search"):post(body):build()
    local result = lib:executeRequest(request, 'https://www.lightnovelpub.com')
    local decoded = lib:decodeUnicode(result:toString())

    local chapterList = lib:jsoupParseHtml(decoded, 'https://www.lightnovelpub.com'):select('li.novel-item')
    local size = chapterList:size()
	local list = lib:createWebsiteSearchList()

    if(size > 0) then
		for i=0,size-1,1 do
			local link = chapterList:get(i):selectFirst('a[href]'):attr('abs:href')
			local title = chapterList:get(i):selectFirst('a[href]'):attr('title')
			local imgSrc = chapterList:get(i):selectFirst('img'):absUrl('src')
			lib:addWebsiteSearchToList(list, link, title, imgSrc)
		end
	end

	return list
end

function parseNovel(url)
	--get info from novels page
	local documentNovel = lib:getDocument(url)
	local websiteNovel = lib:createWebsiteNovel()

	websiteNovel:setTitle(documentNovel:selectFirst(novelTitleElement):text())
	websiteNovel:setImageUrl(documentNovel:selectFirst('div.fixed-img'):selectFirst('img'):attr('data-src'))
	websiteNovel:setDescription(documentNovel:selectFirst('div.summary'):selectFirst('div.content'):text())
	websiteNovel:setAuthor(documentNovel:selectFirst('div.author'):child(1):text())
	websiteNovel:setGenres(documentNovel:selectFirst('div.categories'):child(1):text())
	websiteNovel:setTags(documentNovel:selectFirst('div.tags'):child(1):text())
	websiteNovel:setStatus(documentNovel:selectFirst('div.header-stats'):child(3):child(0):text())

    local urlChapters = documentNovel:selectFirst('.grdbtn.chapter-latest-container'):selectFirst('a[href]'):attr('abs:href')
    local documentPage = lib:getDocument(urlChapters)

    local list = lib:createWebsiteChapterList()

	local hasNext = 1
	while hasNext==1 do
		local docChapters = documentPage:select('ul.chapter-list'):select('li')
		local chaptersCount = docChapters:size()

		for i=0,chaptersCount-1,1 do
			local link = docChapters:get(i):selectFirst('a[href]'):attr('abs:href')
			local title = docChapters:get(i):selectFirst('a[href]'):attr('title')
			lib:addWebsiteChaptersToList(list, link, title, '')
		end

		local nextPage = ''
		local nextPageingElement = documentPage:select('li.PagedList-skipToNext')

		if nextPageingElement == nil then

		else
			nextPageingElement = nextPageingElement:select('a[href]')
			if nextPageingElement == nil then

			else
				nextPage = nextPageingElement:attr('abs:href')
			end
		end

		if #nextPage > 0 then
			documentPage = lib:getDocument(nextPage)
		else
			hasNext = 0
		end
	end

	websiteNovel:setChapters(list)

	return websiteNovel
end