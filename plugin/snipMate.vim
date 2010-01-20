0" File:          snipMate.vim
" Author:        Michael Sanders
" Last Updated:  July 13, 2009
" Version:       0.83
" Description:   snipMate.vim implements some of TextMate's snippets features in
"                Vim. A snippet is a piece of often-typed text that you can
"                insert into your document using a trigger word followed by a "<tab>".
"
"                For more help see snipMate.txt; you can do this by using:
"                :helptags ~/.vim/doc
"                :h snipMate.txt

if exists('loaded_snips') || &cp || version < 700
	finish
endif
let loaded_snips = 1
if !exists('snips_author') | let snips_author = 'Me' | endif

au BufRead,BufNewFile *.snippets\= set ft=snippet
au FileType snippet setl noet fdm=indent


let s:snippets = {} | let s:multi_snips = {}
let g:selN = -1
let s:auTriggers = []
if !exists('snippets_dir')
	let snippets_dir = substitute(globpath(&rtp, 'snippets/'), "\n", ',', 'g')
endif

fun! MakeSnip(scope, trigger, content, ...)
	let multisnip = a:0 && a:1 != ''
	let var = multisnip ? 's:multi_snips' : 's:snippets'
	if !has_key({var}, a:scope) | let {var}[a:scope] = {} | endif
	if !has_key({var}[a:scope], a:trigger)
		let {var}[a:scope][a:trigger] = multisnip ? [[a:1, a:content,a:2,a:3]] : a:content
	elseif multisnip | let {var}[a:scope][a:trigger] += [[a:1, a:content,a:2,a:3]]
	else
		echom 'Warning in snipMate.vim: Snippet '.a:trigger.' is already defined.'
				\ .' See :h multi_snip for help on snippets with multiple matches.'
	endif
endf

fun! ExtractSnips(dir, ft)
	for path in split(globpath(a:dir, '*'), "\n")
		if isdirectory(path)
			let pathname = fnamemodify(path, ':t')
			for snipFile in split(globpath(path, '*.snippet'), "\n")
				call s:ProcessFile(snipFile, a:ft, pathname)
			endfor
		elseif fnamemodify(path, ':e') == 'snippet'
			call s:ProcessFile(path, a:ft)
		endif
	endfor
endf

" Processes a single-snippet file; optionally add the name of the parent
" directory for a snippet with multiple matches.
fun s:ProcessFile(file, ft, ...)
	let keyword = fnamemodify(a:file, ':t:r')
	if keyword  == '' | return | endif
	try
		let text = join(readfile(a:file), "\n")
	catch /E484/
		echom "Error in snipMate.vim: couldn't read file: ".a:file
	endtry
"echom keyword."dididididiididididididididiid"
	return a:0 ? MakeSnip(a:ft, a:1, text, keyword)
			\  : MakeSnip(a:ft, keyword, text)
endf

fun! ExtractSnipsFile(file, ft)
	if !filereadable(a:file) | return | endif
	let text = readfile(a:file)
	let inSnip = 0
	for line in text + ["\n"]
		if inSnip && (line[0] == "\t" || line == '')
			let content .= strpart(line, 1)."\n"
			continue
		elseif inSnip
			call MakeSnip(a:ft, trigger, content[:-2], name,smartIndentType,smartIndentContent)
			let inSnip = 0
		endif

		if line[:6] == 'snippet'
			let inSnip = 1
			let trigger = strpart(line, 8)
			let name = ''
			let smartIndentType = ''
			let smartIndentContent = '' 
			let space = stridx(trigger, ' ') + 1
			if space " Process multi snip
				let name = strpart(trigger, space)
				let smartIndentType = matchstr(name, '^:\zs\S\+\ze')
				let smartIndentContent = matchstr(name,'^:\S\+\s\+\zs.*')
				let trigger = strpart(trigger, 0, space - 1)
			endif
			let content = ''
		elseif line[:8] == 'ausnippet'
			let inSnip = 1
			let trigger = strpart(line, 10)
			call add(s:auTriggers,trigger)

			let name = ''
			let space = stridx(trigger, ' ') + 1
			if space " Process multi snip
				let name = strpart(trigger, space)
				let trigger = strpart(trigger, 0, space - 1)
			endif
			let content = ''
		endif
	endfor
			aug AutoTriggerCmd
				"au CursorMovedI * call ExeAuSnippet()
				""au CursorMovedI * call TriggerSnippet()
			aug END
endf
fun! ResetSnippets()
	let s:snippets = {} | let s:multi_snips = {} | let g:did_ft = {}
endf

let g:did_ft = {}
fun! GetSnippets(dir, filetypes)
	for ft in split(a:filetypes, '\.')
		if has_key(g:did_ft, ft) | continue | endif
		call s:DefineSnips(a:dir, ft, ft)
		if ft == 'objc' || ft == 'cpp' || ft == 'cs'
			call s:DefineSnips(a:dir, 'c', ft)
		elseif ft == 'xhtml'
			call s:DefineSnips(a:dir, 'html', 'xhtml')
		endif
		let g:did_ft[ft] = 1
	endfor
endf

" Define "aliasft" snippets for the filetype "realft".
fun s:DefineSnips(dir, aliasft, realft)
	for path in split(globpath(a:dir, a:aliasft.'/')."\n".
					\ globpath(a:dir, a:aliasft.'-*/'), "\n")
		call ExtractSnips(path, a:realft)
	endfor
	for path in split(globpath(a:dir, a:aliasft.'.snippets')."\n".
					\ globpath(a:dir, a:aliasft.'-*.snippets'), "\n")
		call ExtractSnipsFile(path, a:realft)
	endfor
endf
fun InAuTriggers(tri)
	for tmp in s:auTriggers
		if a:tri==tmp
			return 1
		endif
	endfor
	return 0
	
endf
fun ExeAuSnippet()
		let word1 = matchstr(getline('.'), '\S\+\%'.col('.').'c')
		let word2 = matchstr(getline('.'), '\W\+\%'.col('.').'c')
		let word3 = matchstr(getline('.'), '\w\+\%'.col('.').'c')
		if InAuTriggers(word1)||InAuTriggers(word2)||InAuTriggers(word3)
"			call TriggerSnippet()
"			call feedkeys("\<TAB>")
	"		aug! AutoTriggerCmd
		endif
endf

fun! TriggerSnippet()
"先注释掉	
"	if exists('g:SuperTabMappingForward')
"		if g:SuperTabMappingForward == "<tab>"
"			let SuperTabKey = "\<c-n>"
"		elseif g:SuperTabMappingBackward == "<tab>"
"			let SuperTabKey = "\<c-p>"
"		endif
"	endif

"	if pumvisible() " Update snippet if completion is used, or deal with supertab
"		if exists('SuperTabKey')
"			call feedkeys(SuperTabKey) | return ''
"		endif
"		call feedkeys("\<esc>a", 'n') " Close completion menu
"		call feedkeys("\<tab>") | return ''
"	endif
	let s:curLn = line('.')
    if exists('g:snipPos')	
		"let [newWord,s:newS,s:newWidth]= snipMate#getNewWord()
		"错误，疑问 问什么以下代码会将字符's'同时替换掉？
		"let newWord = substitute(newWord,"[\s\t]",'','g')
		let triggers = snipMate#getNewWord()
		for triggerD in triggers
			let newWord=triggerD[0]
			let s:newS = triggerD[1]
			let s:newWidth = triggerD[2]
"		echoe newWord."-".s:newS."-".s:newWidth
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(newWord, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
				let g:snipPos1 = deepcopy(g:snipPos)
				let g:cancelAu = 0
				let s:indent1=g:indent
				let s:lastLine1 = g:lastLine
				let col = col('.') - len(trigger)
				let s:curCol = col
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"sil exe 's/\V'.escape(trigger, '/.').'//'
				let g:currentPos = snipMate#getCurPos() 
				call snipMate#removeSnippet()
				"echoe 'in flag  expanedSnip'
				let s:expandedSnip = snipMate#expandSnip(snippet, col, indent)
				let s:indent2=g:indent
				let s:lastLine2=g:lastLine
				let g:inFlag = 1
				let g:inFlag1 = 1
				let g:snipPos2 = deepcopy(g:snipPos)				
				"call feedkeys('second')
			"	call snipMate#removeSnippet()
				call JoinSnipPos() 
				return s:expandedSnip

				"return s:expandedSnip
				" feedkeys(s:expandedSnip)
				"return snipMate#getCurPos()
			endif
		endfor
		endfor
				return snipMate#jumpTabStop(-1) 
	endif



		let word = matchstr(getline('.'), '\.\w\+\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"echoe 'snipMate expandSnip'
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor


		let word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"echoe 'snipMate expandSnip'
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor



		let word = matchstr(getline('.'), '\W\+\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
		"	echoe trigger
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"exe 's/\V'.escape(trigger, '/.').'\%#//'
				"call feedkeys('not exist g:snipPos')
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor


		let word = matchstr(getline('.'), '\w\+\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"exe 's/\V'.escape(trigger, '/.').'\%#//'
				"call feedkeys('not exist g:snipPos')
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor



		let word = matchstr(getline('.'), '\d\+\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"exe 's/\V'.escape(trigger, '/.').'\%#//'
				"call feedkeys('not exist g:snipPos')
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor


		let word = matchstr(getline('.'), '\h\+\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"exe 's/\V'.escape(trigger, '/.').'\%#//'
				"call feedkeys('not exist g:snipPos')
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor



		let word = matchstr(getline('.'), '\W\+\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"exe 's/\V'.escape(trigger, '/.').'\%#//'
				"call feedkeys('not exist g:snipPos')
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor


		let word = matchstr(getline('.'), '\s*\w\+\zs\W\S*\%'.col('.').'c')
		for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
			let [trigger, snippet,indent] = s:GetSnippet(word, scope)
			" If word is a trigger for a snippet, delete the trigger & expand
			" the snippet.
			if snippet != ''
		"	echoe trigger
				let col = col('.') - len(trigger)
				sil exe 's/\V'.escape(trigger, '/.').'\%#//'
				"exe 's/\V'.escape(trigger, '/.').'\%#//'
				"call feedkeys('not exist g:snipPos')
				return snipMate#expandSnip(snippet, col,indent)
			endif
		endfor







		if exists('SuperTabKey')
			call feedkeys(SuperTabKey)
			return ''
		endif
		return "\<tab>"
	endf




	fun JoinSnipPos()

		let s:len1 =  len(g:snipPos1)
		let s:len2 = len(g:snipPos2)
		let s:tolen = s:len1+s:len2
		let s:count = 0

		call snipMate#setSnipLen(s:tolen)
		let g:snipPos3 = []
		let g:snipPos = []
		let s:tmpPos = []
		let s:counterL = 0
		let s:counterC = 0


				if g:selN!=-1
					let s:selN = g:selN
					let g:selN = -1
				else
					let s:selN = 0
				endif

				
		while s:count<s:tolen 
			call add(g:snipPos3,[0,0,-1])


			if s:count >g:currentPos && s:count <=g:currentPos+s:len2
				let g:snipPos3[s:count] = g:snipPos2[s:count-g:currentPos-1]
				call add(s:tmpPos,[g:snipPos3[s:count][0]-s:curLn,g:snipPos3[s:count][1]])
			else
				if s:count <= g:currentPos
					let g:snipPos3[s:count] = g:snipPos1[s:count]
				else
					let s:counterL = g:totalLine-1
					let g:snipPos3[s:count] = g:snipPos1[s:count-s:len2]
				endif

				if g:snipPos3[s:count][0]<=g:snipPos1[g:currentPos][0] && g:snipPos3[s:count][1]<=g:snipPos1[g:currentPos][1]
				else
					let g:snipPos3[s:count][0] += s:counterL
					if g:snipPos3[s:count][0]==g:snipPos1[g:currentPos][0]+s:counterL
						let g:snipPos3[s:count][1] += len(s:lastLine2)+s:newWidth 
						let g:snipPos3[s:count][1] -= s:selN
					endif
				endif

				if exists('g:snipPos3[s:count][3]')
					for posTmp in g:snipPos3[s:count][3]
						if posTmp[0]<=g:snipPos1[g:currentPos][0] && posTmp[1]<=g:snipPos1[g:currentPos][1]
						else
							let posTmp[0] += s:counterL
							if posTmp[0]==g:snipPos1[g:currentPos][0]+s:counterL
								let posTmp[1] += len(s:lastLine2)+s:newWidth 
								let posTmp[1] -= s:selN
							endif
						endif
					endfor
				endif
			endif


				let s:count += 1
			endwhile


			let g:snipPos3[g:currentPos][1]=s:curCol
			let g:snipPos = deepcopy(g:snipPos3)
			if g:snipPos[g:currentPos][2]==-2
				unl g:snipPos[g:currentPos][3]
				let g:snipPos[g:currentPos][2]=-1
			endif
			unl g:snipPos3 g:snipPos1 g:snipPos2 s:tmpPos
			call snipMate#setCurPos(g:currentPos+1)
			return len(g:snipPos)

		endf









		fun JoinSnipPosBak()

			let s:len1 =  len(g:snipPos1)
			let s:len2 = len(g:snipPos2)
			let s:tolen = s:len1+s:len2
			let s:count = 0

			call snipMate#setSnipLen(s:tolen)
			let g:snipPos3 = []
			let g:snipPos = []
			let s:tmpPos = []
			let s:counterL = 0
			let s:counterC = 0


					if g:selN!=-1
						let s:selN = g:selN
				"		echoe s:selN
						let g:selN = -1
					else
						let s:selN = 0
					endif

					
			"try
			while s:count<s:tolen 
				call add(g:snipPos3,[0,0,-1])
				if s:count <= g:currentPos
					let g:snipPos3[s:count] = g:snipPos1[s:count]
				elseif s:count >g:currentPos && s:count <=g:currentPos+s:len2
					"call add(s:tmpPos,[0,0])
					let g:snipPos3[s:count] = g:snipPos2[s:count-g:currentPos-1]
					call add(s:tmpPos,[g:snipPos3[s:count][0]-s:curLn,g:snipPos3[s:count][1]])
					"echoe s:tmpPos[s:count-g:currentPos-1][0]."--".s:tmpPos[s:count-g:currentPos-1][1]
					"let s:tmpPos[0]= g:snipPos3[s:count][0]-s:curLn
					"let s:tmpPos[1]= g:snipPos3[s:count][1]-s:curLn
				else
					"let s:counterL=2
					let s:counterL = g:totalLine-1
					let g:snipPos3[s:count] = g:snipPos1[s:count-s:len2]
					let g:snipPos3[s:count][0] += s:counterL
		"				echoe g:snipPos2[-1][1]
					if g:snipPos3[s:count][0]==g:snipPos3[g:currentPos][0]+s:counterL
						let g:snipPos3[s:count][1] += len(s:lastLine2)+s:newWidth 
						let g:snipPos3[s:count][1] -= s:selN
					endif


				endif
				let s:count += 1
			endwhile
		"	catch
		"		call feedkeys('error:error')
		"	endtry
		"	call add(g:snipPos,[0,0,-1])
			let g:snipPos = deepcopy(g:snipPos3)
			if g:snipPos[g:currentPos][2]==-2
				unl g:snipPos[g:currentPos][3]
				let g:snipPos[g:currentPos][2]=-1
			endif
			unl g:snipPos3 g:snipPos1 g:snipPos2 s:tmpPos
			call snipMate#setCurPos(g:currentPos+1)
			return len(g:snipPos)

		endf

		
		fun! BackwardsSnippet(e)
			if exists('g:snipPos') | return snipMate#jumpTabStop(-2) | endif

			if exists('g:SuperTabMappingForward')
				if g:SuperTabMappingBackward == "<s-tab>"
					let SuperTabKey = "\<c-p>"
				elseif g:SuperTabMappingForward == "<s-tab>"
					let SuperTabKey = "\<c-n>"
				endif
			endif
			if exists('SuperTabKey')
				call feedkeys(SuperTabKey)
				return ''
			endif
			return "\<s-tab>"
		endf

		fun! NextLine(e)
			if exists('g:snipPos') && a:e| return snipMate#jumpTabStop(-5) | endif
			if exists('g:snipPos') && !a:e| return snipMate#jumpTabStop(-3) | endif

			if exists('g:SuperTabMappingForward')
				if g:SuperTabMappingBackward == "<s-tab>"
					let SuperTabKey = "\<c-p>"
				elseif g:SuperTabMappingForward == "<s-tab>"
					let SuperTabKey = "\<c-n>"
				endif
			endif
			if exists('SuperTabKey')
				call feedkeys(SuperTabKey)
				return ''
			endif
			return "\<s-tab>"
		endf

fun! NewLine()
	if exists('g:snipPos')
		let curPos = snipMate#getCurPos()
		call snipMate#jumpTabStop(curPos)
		let posTmp = []
		call add(posTmp,[0,0,-1])
		let num = 0
		let curLine = line('.')
		let flagPos = -1
		for pos in g:snipPos
			if pos[0] > curLine	
				if flagPos == -1
					let flagPos = num 
				endif
				"let pos[0] += 1
			endif
			if exists('g:snipPos[3]')
				for pos3 in g:snipPos[3]
					if pos3[0]> curLine
					"	let pos3[0] += 1
					endif
				endfor
			endif
			let num += 1
		endfor
		let snipLen = num + 1
		if flagPos == -1
			let flagPos = snipLen -1
		endif

		let num = 0
		for pos in g:snipPos
			call add(posTmp,[0,0,-1])
			if num < flagPos 
				let posTmp[num] = g:snipPos[num]
			elseif num >= flagPos
				let posTmp[num+1] = g:snipPos[num]
			endif
			let num += 1	
		endfor
			let posTmp[flagPos] = [curLine,len(getline(curLine))+1,-1]
			let g:snipPos=posTmp
			call snipMate#setSnipLen(snipLen)
			call snipMate#jumpTabStop(flagPos)
	"		call cursor(line('.'),0)
	"call cursor(curLine,col('$'))
	call feedkeys("\<enter>")
"	let g:snipPos=posTmp
"	call snipMate#setSnipLen(snipLen)
"	let g:snipPos[flagPos][1]=col('.')
"	call snipMate#setCurSnipPos(flagPos)
	else
		call feedkeys("\<esc>o")
	endif
	return ''
endf










	fun! JumpLine(e)
			if exists('g:snipPos') | return snipMate#jumpTabStop(a:e) | endif
			call feedkeys("\<esc>".a:e."a")
			return ''
			if exists('g:SuperTabMappingForward')
				if g:SuperTabMappingBackward == "<s-tab>"
					let SuperTabKey = "\<c-p>"
				elseif g:SuperTabMappingForward == "<s-tab>"
					let SuperTabKey = "\<c-n>"
				endif
			endif
			if exists('SuperTabKey')
				call feedkeys(SuperTabKey)
				return ''
			endif
			return "\<s-tab>"
		endf

		" Check if word under cursor is snippet trigger; if it isn't, try checking if
		" the text after non-word characters is (e.g. check for "foo" in "bar.foo")
		fun s:GetSnippet(word, scope)
			let word = a:word | let snippet = ''
			let indent = -1
			while snippet == ''
				if exists('s:snippets["'.a:scope.'"]["'.escape(word, '\"').'"]')
					let snippet = s:snippets[a:scope][word]
				elseif exists('s:multi_snips["'.a:scope.'"]["'.escape(word, '\"').'"]')
					let snips = s:multi_snips[a:scope][escape(word, '\"')]
					let [snippet,indent] = s:AuChooseSnippet(snips)
					if snippet ==''
					"	let snippet = s:ChooseSnippet(a:scope, word)
					endif
					if snippet == '' | break | endif
				else
					break
				"	if match(word, '\W') == -1 | break | endif
				"	let word = substitute(word, '.\{-}\W', '', '')
				endif
			endw
		"	if word == '' && a:word != '.' && stridx(a:word, '.') != -1
		"		let [word, snippet] = s:GetSnippet('.', a:scope)
		"	endif
			return [word, snippet, indent]
		endf

		fun s:AuChooseSnippet(snips)
			for snip in a:snips
				let type = snip[2]
				let con = snip[3]
				let snippet = snip[1]
				if type == 'if'
					exe	"if ".con."| return [snippet,-1]"."|endif"
				elseif type == 'reg'
					let s = match(getline('.'),con)
					if s != -1
						return [snippet,s+1]
					endif
				endif
			endfor
			return ['',-1]
		endf

		fun s:ChooseSnippet(scope, trigger)
			let snippet = []
			let i = 1
			for snip in s:multi_snips[a:scope][a:trigger]
				let snippet += [i.'. '.snip[0]]
				let i += 1
			endfor
			if i == 2 | return s:multi_snips[a:scope][a:trigger][0][1] | endif
			let num = inputlist(snippet) - 1
			return num == -1 ? '' : s:multi_snips[a:scope][a:trigger][num][1]
		endf

		fun! ShowAvailableSnips()
			let line  = getline('.')
			let col   = col('.')
			let word  = matchstr(getline('.'), '\S\+\%'.col.'c')
			let words = [word]
			if stridx(word, '.')
				let words += split(word, '\.', 1)

			endif
			let matchlen = 0
			let matches = []
			for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
				let triggers = has_key(s:snippets, scope) ? keys(s:snippets[scope]) : []
				if has_key(s:multi_snips, scope)
					let triggers += keys(s:multi_snips[scope])
				endif
				for trigger in triggers
					for word in words
						if word == ''
							let matches += [trigger] " Show all matches if word is empty
						elseif trigger =~ '^'.word
							let matches += [trigger]
							let len = len(word)
							if len > matchlen | let matchlen = len | endif
						endif
					endfor
				endfor
			endfor

			" This is to avoid a bug with Vim when using complete(col - matchlen, matches)
			" (Issue#46 on the Google Code snipMate issue tracker).
			call setline(line('.'), substitute(line, repeat('.', matchlen).'\%'.col.'c', '', ''))
			call complete(col, matches)
			return ''
		endf
		" vim:noet:sw=4:ts=4:ft=vim
