expected <- eval(parse(text="integer(0)"));     
test(id=0, code={     
argv <- eval(parse(text="list(character(0), \"c\", FALSE)"));     
.Internal(`nchar`(argv[[1]], argv[[2]], argv[[3]]));     
}, o=expected);     

