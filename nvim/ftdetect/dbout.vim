" Filetype detection for DBUI output files
autocmd BufRead,BufNewFile *.dbout setfiletype dbout
autocmd BufRead,BufNewFile *DBUI* if &filetype == '' | setfiletype dbout | endif
