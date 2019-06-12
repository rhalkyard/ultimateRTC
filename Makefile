AS = ca65
CC = cl65

BINDIR = bin
OBJDIR = obj
RESOBJ = $(OBJDIR)/res
DEPDIR = dep
SRCDIR = src

IMGTYPE := d64

MOCK := 

CFLAGS = -g -t geos-cbm -T --listing $(basename $@).lst --bin-include-dir $(RESOBJ) --create-dep $(DEPDIR)/$(notdir $@).dep
ASFLAGS = -g -t geos-cbm -I ./inc/ --bin-include-dir $(RESOBJ) --create-dep $(DEPDIR)/$(notdir $@).dep --listing $(basename $@).lst
LDFLAGS = -t geos-cbm -Ln $(basename $@).lbl --mapfile $(basename $@).map -Wl --dbgfile,$(basename $@).dbg
 
PRG = ultimateRTC
SRCS = header.grc ultimateRTC.s ucommand.s
BITMAPS = ultimateRTC.xcf
ICONS = ultimateRTC.xcf

ifneq (MOCK,)
CFLAGS += -DMOCK
ASFLAGS += -DMOCK
endif

RESBITMAPS = $(foreach b,$(BITMAPS),$(RESOBJ)/$(basename $b).bitmap.bin)
RESICONS = $(foreach i,$(ICONS),$(RESOBJ)/$(basename $i).icon.bin)
_SRCS = $(foreach s,$(SRCS),$(SRCDIR)/$s)

RES	    = $(RESBITMAPS) $(RESICONS)
OBJS 	= $(foreach s,$(_SRCS),$(OBJDIR)/$(basename $(notdir $s)).o)

all: $(RES) $(PRG) $(PRG).$(IMGTYPE)

bootdisks: boot64.$(IMGTYPE) boot128.$(IMGTYPE)

$(PRG): $(PRG).cvt

clean:
	rm -rf $(OBJDIR) $(PRG).{d64,d71,d81,cvt,dbg,lbl,map}

zap: clean
	rm -rf $(DEPDIR)

$(PRG).$(IMGTYPE): $(PRG).cvt
	c1541 -format $(PRG),11 $(IMGTYPE) $@
	c1541 -attach $@ $(foreach f,$^,-geoswrite $f)

boot64.d64: $(PRG).cvt | GEOS64.D64
	cp GEOS64.D64 $@
	c1541 -attach $@ $(foreach f,$^,-geoswrite $f)

boot128.d64: $(PRG).cvt | GEOS128.D64
	cp GEOS128.D64 $@
	c1541 -attach $@ $(foreach f,$^,-geoswrite $f)

.PHONY: all bootdisks clean zap $(PRG)

.INTERMEDIATE: $(addprefix res/,$(addsuffix .pcx,$(basename $(filter-out .pcx,$(BITMAPS) $(ICONS)))))

$(PRG).cvt: $(OBJS)

%.cvt:
	$(CC) $(LDFLAGS) -o $@ $+

$(OBJDIR)/%.s: $(SRCDIR)/%.grc | $(OBJDIR) $(DEPDIR)
	grc65 -s $@  $<

$(OBJDIR)/%.o: $(SRCDIR)/%.s | $(OBJDIR) $(DEPDIR) 
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR) $(DEPDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

%.png: %.xcf
	convert -flatten $< $@

# sp65 only understands .PCX images; use imagmagick to convert from .PNG
%.pcx: %.png
	convert $< $@

$(RESBITMAPS): $(RESOBJ)/%.bitmap.bin: res/%.pcx | $(RESOBJ)
	sp65 -r $< -c geos-bitmap -w $@

$(RESICONS): $(RESOBJ)/%.icon.bin: res/%.pcx | $(RESOBJ)
	sp65 -r $< -c geos-icon -w $@

$(OBJDIR) $(RESOBJ) $(DEPDIR):
	mkdir -p $@

-include dep/*.dep
