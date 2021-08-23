using DelimitedFiles, StatsBase

# download file from open lyrics github 
file = download("https://raw.githubusercontent.com/Lyrics/lyrics/4040fb49c17fd317fcac21259cd7109a04585227/database/K/Kanye%20West/Late%20Registration/Gold%20Digger")
# read data from where it was downloaded
data = readdlm(file, '\n')

## uncomment below to save data
# open("yeezy_lyrics.txt", "w") do io
#     for line in data 
#         println(io, line)
#     end
# end

# data is an array where each element is a line of lyrics
# lowercase(string) converts a string to lowercase
# lowercase.(ArrayOfStrings) boradcasts lowercase of each string in the array
data = lowercase.(data)

# remove punctiation 
data = filter.(!ispunct,data) 

# split at spaces
data = split.(data)

# will contain all the words as keys and counters of the number of 
# times they appear as values
words = Dict{String,Int}()
for line in data # loop of elements in array (which are lines of lyrics)
    for w in line # loop over words in line
        if w ∈ keys(words) # this is sexy 
            words[w] += 1 # increments the counter
        else
            words[w] = 1 # creates a counter when one does not exist
        end
    end
end

# will contain words as keys and dictionaries as values
# the dictionaries will have all occurances of following words 
# as keys and all counters for how many times they appear as values
bigrams = Dict{String,Dict{String,Int}}()
for line in data 
    for (index, word) in enumerate(line) 
        if index < length(line) && word ∈ keys(bigrams) # if curr word not at end of line and is all ready in the dict
            next_word = line[index+1]
            if next_word ∈ keys(bigrams[word]) # if the next word is already in the dict
                bigrams[word][next_word] += 1 
            else 
                bigrams[word][next_word] = 1 
            end
        elseif index < length(line) # create new entry as one does not exist
            next_word = line[index+1]
            bigrams[word] = Dict{String,Int}(next_word => 1)
        else # it is the end of a line, so the next word is an end-of-line chatacter \n
            if word ∈ keys(bigrams) && "\n" ∈ keys(bigrams[word])
                bigrams[word]["\n"] += 1
            else 
                bigrams[word] = Dict{String,Int}("\n" => 1)
            end
        end
    end
end

# count all words at the start of lines
roots = Dict{String,Int}()
for line in data 
    length(line)>0 && if line[1] ∈ keys(roots)
            roots[line[1]] += 1
        else
            roots[line[1]] = 1
       end
end

```

    generate_line(bigrams, root)

bigrams::Dict as constructed above, used to sample the next word dependent on the current
root::String a word to start the sentence
```
function generate_line(bigrams, root)
    line = root # initialise line 
    curr_word = root 
    while curr_word != "\n" # not end of line 
        next_words = bigrams[curr_word] # find all next words
        # sample from possible next words with weight how many times they have appeared
        next_word = sample(collect(keys(next_words)),Weights(collect(values(next_words)))) 
        line = [line; next_word] # add to end of line 
        curr_word = next_word
    end
    return join(line, ' ') # return a string 
end

rand_root() = sample(collect(keys(roots)),Weights(collect(values(roots)))) # sample a random root word 

generate_line(bigrams,rand_root()) # simulate a line 
