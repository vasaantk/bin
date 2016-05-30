frmodel : frmodel.o flatrot.o inqradc.o eqtogalp.o parallax.o eqtoecl.o solmot.o
	g77 -o frmodel frmodel.o flatrot.o inqradc.o eqtogalp.o parallax.o eqtoecl.o solmot.o
frmodel.o : frmodel.f
	g77 -c frmodel.f
flatrot.o : flatrot.f
	g77 -c flatrot.f
inqradc.o : inqradc.f
	g77 -c inqradc.f
eqtogalp.o : eqtogalp.f
	g77 -c eqtogalp.f
parallax.o : parallax.f
	g77 -c parallax.f
eqtoecl.o : eqtoecl.f
	g77 -c eqtoecl.f
solmot.o : solmot.f
	g77 -c solmot.f

