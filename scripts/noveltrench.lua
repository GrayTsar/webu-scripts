local novelTitleElement = 'div.post-title'
local novelImageUrlElement = 'div.summary_image'
local novelDescriptionElement = 'div.description-summary'
local novelGenresElement = 'div.genres-content'
local chapterListElement = 'li.wp-manga-chapter'
local searchNovelsElement = 'div.c-tabs-item__content'
local chapterTextElement = 'div.c-blog-post'

local ajaxChapterRelativeUrl = 'ajax/chapters/'

function getChapterText(url) 
	local document = lib:getDocument(url)
	local text = document:selectFirst(chapterTextElement):selectFirst('div.text-left'):toString()

	return text
end

function search(searchQuery)
	local url = 'https://noveltrench.com/?s=' .. searchQuery .. '&post_type=wp-manga'
	local document = lib:getDocument(url)
	local documentSearchResult = document:select(searchNovelsElement)

	local list = lib:createWebsiteSearchList()

	local searchCount = documentSearchResult:size()
	if(searchCount > 0) then
		for i=0,searchCount-1,1 do
			local link = documentSearchResult:get(i):selectFirst('a[href]'):attr('abs:href')
			local title = documentSearchResult:get(i):selectFirst('a[href]'):attr('title')
			local imgSrc = documentSearchResult:get(i):selectFirst('img'):absUrl('data-src')
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
	websiteNovel:setImageUrl(documentNovel:selectFirst(novelImageUrlElement):selectFirst('img'):absUrl('data-src'))
	websiteNovel:setDescription(documentNovel:selectFirst(novelDescriptionElement):text())
	--websiteNovel:setAuthor(documentNovel:selectFirst(novelAuthorElement):text())
	websiteNovel:setAuthor('')
	websiteNovel:setGenres(documentNovel:selectFirst(novelGenresElement):text())
	--websiteNovel:setTags(documentNovel:selectFirst(novelTagsElement):text())
	websiteNovel:setTags('')
	--websiteNovel:setStatus(documentNovel:selectFirst(novelStatusElement):select('div.summary-content'):last():text())
	websiteNovel:setStatus('')

	--get chapters list from ajax request
	local documentChapters = lib:postDocument(url .. ajaxChapterRelativeUrl)
	local chaptersIndex = documentChapters:select(chapterListElement)

	local list = lib:createWebsiteChapterList()
	local chaptersCount = chaptersIndex:size()
	print('DBG: ' .. documentChapters:html())

	if(chaptersCount > 0) then
		for i=0,chaptersCount-1,1 do
			local link = chaptersIndex:get(i):selectFirst('a[href]'):attr('abs:href')
			local title = chaptersIndex:get(i):selectFirst('a'):text()
			lib:addWebsiteChaptersToList(list, link, title, '')
		end
	end

	websiteNovel:setChapters(list)

	return websiteNovel
end