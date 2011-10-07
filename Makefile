GL=./gen_ladder.pl
DOT=dot

default:

%.png:	%.lad $(GL)
	$(GL) $< $@

clean:
	rm *.dot *.ps *.svg *.png
