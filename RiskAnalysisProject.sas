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
data alior2;
	set work.alior;
	L_alior=L_alior+100;
run;

proc severity data=alior2 print=all plots=qq;
	loss L_alior;
	dist GAMMA LOGN WEIBULL LOGLOGISTIC;
run;

proc univariate data=alior2 normaltest;
	var L_alior;
	histogram L_alior / weibull (SIGMA=EST THETA=EST C=EST) normal 
		lognormal (ZETA=EST THETA=EST SIGMA=EST);
	qq L_alior / normal;
	qq L_alior /weibull(SIGMA=EST THETA=EST C=EST);
	qq L_alior / lognormal(ZETA=EST THETA=EST sigma=EST);
run;

proc severity data=alior2 obj=cvmobj print=all plots=qq;
	loss L_alior;
	dist EXP GPD IGAUSS LOGN PARETO WEIBULL GAMMA;
	cvmobj=_cdf_(L_alior);
	cvmobj=(cvmobj -_edf_(L_alior))**2;
run;

data pko2;
	set work.pko;
	L_pko=L_pko+100;
run;

proc severity data=pko2 print=all plots=qq;
	loss L_pko;
	dist GAMMA LOGN WEIBULL;
run;

proc univariate data=pko2 normaltest;
	var L_pko;
	histogram L_pko / lognormal gamma;
run;

/* DOPASOWANIE ROZKLADOW - OSTATECZNE */
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
	tests={'Na podstawie skośności', 'Na podstawie kurtozy'};
	estymatory={13.76748411, 5.21007803};
	p_value={0.00807534741616953, 1.88761221542322E-07};
	print s;
	print s_inv;
	print "Mardia Test";
	print tests[L="  "] estymatory[L="Estymator"] p_value[L="Wartość p"];
run;

/* VaR */
proc iml;
	var={'Value-at-Risk - metoda analityczna', 
		'Value-at-Risk - kwantyl empiryczny'};
	alior={19.4917, 17.59755};
	pko={11.94966, 9.12390};
	print var[L="  "] alior[L="Alior Bank"] pko[L="PKO BP"];
run;

/* Expected Shortfall */
proc sort data=alior out=alior_sort;
	by descending L_alior;

proc means data=alior_sort (obs=3) mean;
	var L_alior;
run;

proc sort data=pko out=pko_sort;
	by descending L_pko;

proc means data=pko_sort (obs=3) mean;
	var L_pko;
run;

/* Wartości na podstawie programu R */
proc iml;
	es={'Expected Shortfall - z kwantyla empirycznego', 
		'Expected Shortfall - z metody analitycznej'};
	alior={31.4777, 23.82142};
	pko={17.2293, 14.91499};
	print es[L="  "] alior[L="Alior Bank"] pko[L="PKO BP"];
run;

/* Dopasowanie kopuł + symulacja*/
data laczna;
	set alior (keep=L_alior);
	set pko (keep=L_pko);
run;

/* CLAYTON */
proc copula data=laczna;
	title "Kopula Claytona";
	var L_alior L_pko;
	fit clayton/outcopula=clayton_parametry;
run;

proc copula;
	title "Kopula Claytona";
	var u v;
	define c_cop clayton (theta=0.794450);
	simulate c_cop/seed=1234 ndraws=1000 outuniform=clayton_jednorodne 
		plots=(datatype=UNIFORM distribution=CDF);
run;

/* FRANK */
proc copula data=laczna;
	title "Kopula Franka";
	var L_alior L_pko;
	fit frank/outcopula=frank_parametry;
run;

proc copula;
	title "Kopula Franka";
	var u v;
	define f_cop frank (theta=3.138756);
	simulate f_cop/seed=1234 ndraws=1000 outuniform=frank_jednorodne 
		plots=(datatype=UNIFORM distribution=CDF);
run;

/* GUMBEL */
proc copula data=laczna;
	title "Kopula Gumbela";
	var L_alior L_pko;
	fit gumbel/outcopula=gumbel_parametry;
run;

proc copula;
	title "Kopula Gumbela";
	var u v;
	define g_cop gumbel (theta=1.480122);
	simulate g_cop/seed=1234 ndraws=1000 outuniform=gumbel_jednorodne 
		plots=(datatype=UNIFORM distribution=CDF);
run;

/* KOPULA T */
proc copula data=laczna;
	title "Kopuła t";
	var L_alior L_pko;
	fit t/ outcopula=t_parametry;
run;

proc iml;
	/*deklarowanie macierzy*/
	P={1 0.5183, 0.5183 1};
	create Sasp from P;
	append from P;
	close Sasp;

proc copula;
	title "Kopuła t-studenta";
	var u v;
	define c_cop t (corr=Sasp df=14.627611);
	simulate c_cop/seed=1234 ndraws=1000 outuniform=t_jednorodne 
		plots=(datatype=UNIFORM distribution=CDF);
run;

/* Zestawienie parametrow oraz wynikow dopasowania kopul */
proc iml;
	var={'Parametr', 'LOG', 'AIC', 'SBC'};
	clayton={0.794450, 7.35307, -12.70615, -10.61180};
	frank={3.138756, 6.84837, -11.69674, -9.60240};
	gumbel={1.480122, 7.81485, -13.62971, -11.53537};
	t={14.627611, 8.24208, -12.48417, -8.29548};
	print var[L="  "] clayton[L="Kopuła Claytona"] frank[L="Kopuła Franka"] 
		gumbel[L="Kopuła Gumbela"] t[L="Kopuła t"];
run;

/* Ponowna symulacja najlepiej dopasowanej kopuły (Clayton) */
proc copula;
	title "Kopula Gumbela";
	var u v;
	define g_cop gumbel (theta=1.480122);
	simulate g_cop/seed=1234 ndraws=1000 outuniform=gumbel_jednorodne 
		plots=(datatype=UNIFORM distribution=CDF);
run;

/* Transformacja punktów z kopuły najlepiej dopasowanej (Clayton) w celu uzyskania stóp strat inwestycji w Alior oraz PKO */
data transformacja;
	set gumbel_jednorodne;
	L_alior=quantile('Normal', u, 2.4483, 10.362);
	L_pko=quantile('Normal', v, 0.277, 7.0965);
run;

/* Symulacja wybranych punktow w 3-wymiarze */
ods graphics on;

proc kde data=transformacja;
	bivar L_alior L_pko/ plots=all;
run;

/* Obliczenie miar ryzyka dla portfela dwuwymiarowego */
%macro Kopula (a);
	data div;
		set transformacja;
		L=&a*L_alior+(1-&a)*L_pko;
	run;

	proc univariate data=div;
		var L;
	run;

	proc sort data=div out=div_sort;
		by descending L;

	proc means data=div_sort (obs=50) mean;
		var L;
	run;

%mend;

%Kopula (0) %Kopula (0.1) %Kopula (0.2) %Kopula (0.3) %Kopula (0.4) 
	%Kopula (0.5) %Kopula (0.6) %Kopula (0.7) %Kopula (0.8) %Kopula (0.9) 
	%Kopula (1)
%Kopula (0.1) %Kopula (0.11) %Kopula (0.12) %Kopula (0.13) %Kopula (0.14) %Kopula (0.15) 
%Kopula (0.16) %Kopula (0.17) %Kopula (0.18) %Kopula (0.19) %Kopula (0.2)  
	