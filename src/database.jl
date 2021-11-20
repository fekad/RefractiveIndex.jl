

lib = YAML.load_file(joinpath(DB_ROOT, "library.yml"), dicttype=Dict{String,Any})

for shelf in lib
    shelfname = shelf["SHELF"]
    for book in shelf["content"]
        haskey(book, "DIVIDER") && continue
        bookname = book["BOOK"]
        for page in book["content"]
            haskey(page, "DIVIDER") && continue
            pagename = string(page["PAGE"])
            DB[MaterialCatalog(shelfname, bookname, pagename)] = MaterialEntry(page["name"], page["data"])
        end
    end
end

