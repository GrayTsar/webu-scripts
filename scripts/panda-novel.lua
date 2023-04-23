function getChapterText(url)
    local request = lib:getRequestBuilder():url(url):addHeader("referer", url):build()
    local result = lib:executeRequest(request, 'https://www.panda-novel.com')
    local textResult = result:selectFirst('div#novelArticle2'):select('p')
	return textResult:toString()
end

function search(searchQuery)
    local query = searchQuery:gsub(' ', '%20')
    local searchUrl = 'https://www.panda-novel.com/search/' .. query
    local document = lib:getDocument(searchUrl)
    local result = document:select('li.novel-li')

    local list = lib:createWebsiteSearchList()
	local count = result:size()
	if(count > 0) then
		for i=0,count-1,1 do
			local link = result:get(i):selectFirst('a[href]'):attr('abs:href')
			local title = result:get(i):selectFirst('div.novel-desc'):child(0):text()
			local imgSrc = result:get(i):selectFirst('div.novel-cover'):child(0):attr('v-lazy:background-image'):gsub('\'', '')
			lib:addWebsiteSearchToList(list, link, title, imgSrc)
		end
	end
    return list
end

function parseNovel(url)
	local novelDoc = lib:getDocument(url)
	local webNovel = lib:createWebsiteNovel()
	local id = url:match('(%d+)$')
	local capi = 'https://www.panda-novel.com/api/book/chapters/' .. id

	webNovel:setTitle(novelDoc:selectFirst('div.novel-desc'):child(0):text())
	webNovel:setImageUrl(novelDoc:selectFirst('meta[property=og:image]'):attr("content"))
	webNovel:setDescription(novelDoc:selectFirst("div.synopsis-content"):select("p"):text())
	webNovel:setAuthor(novelDoc:selectFirst('div.novel-desc'):child(1):child(1):text())
	webNovel:setGenres(novelDoc:selectFirst('div.novel-labels'):children():textNodes():toString():gsub('[%[%]]', ''))
	webNovel:setTags(novelDoc:selectFirst('ul.tags-list'):children():eachText():toString():gsub('[%[%]]', ''))
	webNovel:setStatus(novelDoc:select('ul.novel-labs'):get(1):child(1):child(0):text())

	local chapterList = lib:createWebsiteChapterList()

	local hasNext = 1
	local cPage = 1
	while hasNext==1 do
		local cReq = lib:getRequestBuilder():url(capi .. '/' .. cPage):addHeader("referer", url .. '/chapters'):build()
		local cDoc = lib:executeRequest(cReq, 'https://www.panda-novel.com')
		local tree = lib:toJsonTree(cDoc:text())
		local data = lib:getFromJsonObject(tree, 'data')
		local list = lib:getFromJsonObject(data, 'list')
		local pages = data:get('pages'):getAsInt()
		local array = lib:elementAsArray(list)

		local size = array:size()
		for i=0,size-1,1 do
			local element = array:get(i)
			local item = lib:elementAsObject(element)
			local link = 'https://www.panda-novel.com/' .. item:get('chapterUrl'):getAsString()
			local title = item:get("name"):getAsString()
			lib:addWebsiteChaptersToList(chapterList, link, title, '')
		end

		if cPage+1 > pages then
			hasNext = 0
		else
			cPage = cPage + 1
		end
	end

	webNovel:setChapters(chapterList)

	return webNovel
end