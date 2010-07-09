GL=./gen_ladder.pl
DOT=dot

default:

%.dot:	%.lad
	$(GL) $^ > $@

%.ps:	%.dot
	$(DOT) -Tps < $^ > $@

%.svg:	%.dot
	$(DOT) -Tsvg < $^ > $@

clean:
	rm *.dot *.ps *.svg
