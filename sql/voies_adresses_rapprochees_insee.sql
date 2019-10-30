WITH
diff_numero_fantoir
AS
(SELECT numero,fantoir FROM cumul_adresses WHERE insee_com = '__com__' and source = 'CADASTRE'
EXCEPT
SELECT numero,fantoir FROM cumul_adresses WHERE insee_com = '__com__' and source = 'OSM'),
fantoir_numeros_manquants
AS
(SELECT DISTINCT fantoir,count(*) AS a_proposer FROM diff_numero_fantoir GROUP BY 1)
SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		nature_voie||' '||libelle_voie voie,
		j.voie_osm,
		st_x(g.geometrie),
		st_y(g.geometrie),
		COALESCE(s.id_statut,0),
		COALESCE(fm.a_proposer,0)
FROM	fantoir_voie f
JOIN 	(SELECT DISTINCT fantoir,voie_osm
		FROM	cumul_adresses
		WHERE	insee_com = '__com__' AND
				source in ('CADASTRE','OSM')) j
ON		f.code_insee||f.id_voie||f.cle_rivoli = j.fantoir
JOIN	(SELECT DISTINCT fantoir,
				FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
		FROM	cumul_adresses
		WHERE	insee_com = '__com__') g
ON		f.code_insee||f.id_voie||f.cle_rivoli = g.fantoir
LEFT OUTER JOIN	(SELECT fantoir,id_statut
				FROM 	(SELECT	*,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
						FROM 	statut_fantoir
						WHERE	insee_com = '__com__')r
				WHERE	rang = 1) s
ON		j.fantoir = s.fantoir
LEFT OUTER JOIN fantoir_numeros_manquants fm
ON      f.code_insee||f.id_voie||f.cle_rivoli = fm.fantoir
WHERE	f.code_insee = '__com__'	AND
		f.type_voie in ('1','2')	AND
		f.date_annul = '0000000'	AND
		COALESCE(j.voie_osm,'') != ''
ORDER BY 3;
