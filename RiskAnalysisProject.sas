/* WCZYTANIE DANYCH  */
data alior;
	infile '/home/u45181122/risk/alior.csv' delimiter=';' firstobs=2 dsd;
	informat data ANYDTDTE. alior_otwarcie 6.2 alior_zamkniecie 6.2;
	format data DDMMYYS10.;
	input data $ alior_otwarcie $ alior_zamkniecie $;

	/* 	stopa strat */
	L_alior=round(((alior_otwarcie-alior_zamkniecie)/alior_otwarcie)*100, 0.0001);
run;

data pko;
	infile '/home/u45181122/risk/pko.csv' delimiter=';' firstobs=2 dsd;
	informat data ANYDTDTE. pko_otwarcie 6.2 pko_zamkniecie 6.2;
	format data DDMMYYS10.;
	input data $ pko_otwarcie $ pko_zamkniecie $;

	/* 	stopa strat */
	L_pko=round(((pko_otwarcie-pko_zamkniecie)/pko_otwarcie)*100, 0.0001);
run;

/* Analiza otwarcia i zamknięcia */
proc sgplot data=alior;
	series x=data y=alior_zamkniecie /markers lineattrs=(color=DEPK) 
		markerattrs=(color=BIOY);
	xaxis type=time interval=quarter offsetmax=0.05 offsetmin=0.05 
		valuesformat=DDMMYYS10. min='01DEC2015'd max='01OCT2020'd label='Data' 
		labelattrs=(weight=bold size=10);
	yaxis grid label="Wartość" labelattrs=(weight=bold size=10) values=(10 to 90 
		by 10);
	title 'Alior Bank S.A. notowania na zamknięciu w latach 2015-2020';
run;

proc sgplot data=pko;
	series x=data y=pko_zamkniecie /markers lineattrs=(color=VIGB) 
		markerattrs=(color=VPAB);
	xaxis type=time interval=quarter offsetmax=0.05 offsetmin=0.05 
		valuesformat=DDMMYYS10. min='01DEC2015'd max='01OCT2020'd label='Data' 
		labelattrs=(weight=bold size=10);
	yaxis grid label="Wartość" labelattrs=(weight=bold size=10) values=(10 to 50 
		by 5);
	title 'PKO Bank Polski S.A. notowania na zamknięciu w latach 2015-2020';
run;

/* WYŚWIETLENIE STÓP STRAT */
data alior_pko;
	merge alior pko;
	by data;
run;

proc sgplot data=alior_pko;
	series x=data y=alior_zamkniecie /markers lineattrs=(color=DEPK) 
		markerattrs=(color=BIOY) legendlabel='Alior S.A.';
	series x=data y=pko_zamkniecie /markers lineattrs=(color=VIGB) 
		markerattrs=(color=VPAB) legendlabel='PKO BP S.A.';
	xaxis type=time interval=quarter offsetmax=0.05 offsetmin=0.05 
		valuesformat=DDMMYYS10. min='01DEC2015'd max='01OCT2020'd label='Data' 
		labelattrs=(weight=bold size=10);
	yaxis grid label="Wartość" labelattrs=(weight=bold size=10) values=(10 to 90 
		by 10);
	title 'Porównanie notowań na zamknięciu w latach 2015-2020';
run;

ODS PDF file='/home/u45181122/risk/stopystrat.pdf' nopdfnote;
options nodate nonumber;

proc report data=alior_pko nowd;
	column data ('Alior Bank S.A.' alior_otwarcie alior_zamkniecie L_alior) 
		('PKO Bank Polski S.A.' pko_otwarcie pko_zamkniecie L_pko);
	define data / 'Data' display;
	define alior_otwarcie / 'Otwarcie' display;
	define alior_zamkniecie / 'Zamkniecie' display;
	define L_alior / 'Stopa straty' style=[fontweight=bold] display;
	define pko_otwarcie / 'Otwarcie' display;
	define pko_zamkniecie / 'Zamkniecie' display;
	define L_pko / 'Stopa straty' style=[fontweight=bold] display;
	compute L_alior;

		if L_alior > 0 then
			call define(_col_, "style", "style={color=red}");
	endcomp;
	compute L_pko;

		if L_pko > 0 then
			call define(_col_, "style", "style={color=red}");
	endcomp;
run;

ods pdf close;

proc sgplot data=alior_pko;
	series x=data y=L_alior /lineattrs=(color=DEPK) legendlabel='Alior S.A.';
	series x=data y=L_pko /lineattrs=(color=VIGB) legendlabel='PKO BP S.A.';
	xaxis type=time interval=quarter offsetmax=0.05 offsetmin=0.05 
		valuesformat=DDMMYYS10. min='01DEC2015'd max='01OCT2020'd label='Data' 
		labelattrs=(weight=bold size=10);
	yaxis grid label="Wartość" labelattrs=(weight=bold size=10);
	title 'Porównanie stóp strat Alior Bank oraz PKO BP w latach 2015-2020';
run;

/* STATYSTYKI OPISOWE*/
proc univariate data=alior;
	var L_alior;
	histogram L_alior/normal;
	output out=alior_stat n=N min=Min max=Max mean=Średnia median=Mediana 
		var=Wariancja std=STD skew=Skośność kurt=Kurtoza;
run;

proc transpose data=alior_stat out=alior_stat(drop=_LABEL_ 
		rename=(_NAME_=Moment COL1=alior_m));
run;

proc univariate data=pko;
	var L_pko;
	histogram L_pko/normal weibull(theta=-250, c=30);
	output out=pko_stat n=N min=Min max=Max mean=Średnia median=Mediana 
		var=Wariancja std=STD skew=Skośność kurt=Kurtoza;
run;

proc transpose data=pko_stat out=pko_stat(drop=_LABEL_ rename=(_NAME_=Moment 
		COL1=pko_m));
run;

data aliorpko_stat;
	merge alior_stat pko_stat;
	input number;
	datalines;
1
4
7
8
6
9
3
5
2
;
run;

proc sort data=aliorpko_stat;
	by number;
run;

data aliorpko_stat;
	set aliorpko_stat;
	drop number;
run;

proc report data=aliorpko_stat nowd;
	column moment ('Momenty' alior_m pko_m);
	define moment / '    ' style(column)=[fontweight=bold] display;
	define alior_m / 'Alior Bank S.A.' display;
	define pko_m / 'PKO Bank Polski S.A.' display;
run;

/* -------------------- */
/* DOPASOWANIE ROZKŁADOW */
proc univariate data=alior normaltest;
	var L_alior;
	histogram L_alior / weibull (SIGMA=EST THETA=EST C=EST) gamma (THETA=EST) 
		lognormal (ZETA=EST THETA=EST SIGMA=EST) normal;
	qqplot L_alior / normal;
run;

proc severity data=alior print=all;
	loss L_alior;
	dist weibull beta logn;
run;

proc univariate data=pko;
	var L_pko;
	histogram L_pko / weibull (SIGMA=EST THETA=EST C=EST) lognormal (ZETA=EST 
		THETA=EST SIGMA=EST) beta (theta=est sigma=est) normal;
run;

proc severity data=pko print=all;
	loss L_pko;
	dist weibull beta logn normal;
run;

/* TEST MARDII WIELOWYMIAROWY ROZKLAD NORMALNY */
data work.cork;
	merge work.alior work.pko;
run;

proc iml;
	* Read data into IML ;
	use work.cork;
	read all;
	* combine L_kawa L_kakao into a matrix X ;
	y=L_alior || L_pko;
	print y;
	n=nrow(y);
	p=ncol(y);
	dfchi=p*(p+1)*(p+2)/6;
	q=i(n) - (1/n)*j(n, n, 1);
	s=(1/(n))*t(y)*q*y;
	s_inv=inv(s);
	g_matrix=q*y*s_inv*t(y)*q;
	beta1hat=(sum(g_matrix#g_matrix#g_matrix) )/(n*n);
	beta2hat=trace(g_matrix#g_matrix)/n;
	kappa1=n*beta1hat/6;
	kappa2=(beta2hat - p*(p+2) ) / sqrt(8*p*(p+2)/n);
	pvalskew=1 - probchi(kappa1, dfchi);
	pvalkurt=2*(1 - probnorm(abs(kappa2)) );
	tests= {'Na podstawie skośności', 'Na podstawie kurtozy'};
	estymatory = {13.76748411, 5.21007803};
	p_value= {0.00807534741616953, 1.88761221542322E-07};
	print s;
	print s_inv;
	print "Mardia Test";
	print tests[L="  "]
	      estymatory[L="Estymator"]
	      p_value[L="Wartość p"];
run;

/* VaR */
proc iml;
var={'Value-at-Risk - metoda analityczna', 'Value-at-Risk - kwantyl empiryczny'};
alior={19.4917, 17.59755};
pko={11.94966, 9.12390};
print var[L="  "]
      alior[L="Alior Bank"]
      pko[L="PKO BP"];
run;

/* Expected Shortfall */
proc iml;
es={'Expected Shortfall'};
alior={23.82142};
pko={14.91499};
print es[L="  "]
      alior[L="Alior Bank"]
      pko[L="PKO BP"];
run;