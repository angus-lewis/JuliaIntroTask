using DelimitedFiles, StatsBase

file = download("https://raw.githubusercontent.com/Lyrics/lyrics/4040fb49c17fd317fcac21259cd7109a04585227/database/K/Kanye%20West/Late%20Registration/Gold%20Digger")
data = readdlm(file, '\n')
# open("yeezy_lyrics.txt", "w") do io
#     for line in data 
#         println(io, line)
#     end
# end

data = lowercase.(data)

data = filter.(!ispunct,data) 

data = split.(data)

words = Dict{String,Int}()
for line in data 
    for w in line
        if w ∈ keys(words)
            words[w] += 1 
        else
            words[w] = 1 
        end
    end
end

bigrams = Dict{String,Dict{String,Int}}()
for line in data 
    for (index, word) in enumerate(line)
        if index < length(line) && word ∈ keys(bigrams)
            next_word = line[index+1]
            if next_word ∈ keys(bigrams[word])
                bigrams[word][next_word] += 1
            else 
                bigrams[word][next_word] = 1
            end
        elseif index < length(line) 
            next_word = line[index+1]
            bigrams[word] = Dict{String,Int}(next_word => 1)
        else 
            if word ∈ keys(bigrams) && "\n" ∈ keys(bigrams[word])
                bigrams[word]["\n"] += 1
            else 
                bigrams[word] = Dict{String,Int}("\n" => 1)
            end
        end
    end
end

roots = Dict{String,Int}()
for line in data 
    length(line)>0 && if line[1] ∈ keys(roots)
            roots[line[1]] += 1
        else
            roots[line[1]] = 1
       end
end

function generate_line(bigrams, root)
    line = root 
    curr_word = root 
    while curr_word != "\n"
        next_words = bigrams[curr_word]
        next_word = sample(collect(keys(next_words)),Weights(collect(values(next_words))))
        line = [line; next_word]
        curr_word = next_word
    end
    return join(line, ' ')
end

rand_root() = sample(collect(keys(roots)),Weights(collect(values(roots))))

generate_line(bigrams,rand_root())
