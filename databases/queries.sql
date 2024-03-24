--12. FORMULAREA ?I REZOLVAREA A 5 CERERI SQL
--CEREREA I
--Sa se afiseze pentru fiecare taxa ID-ul, suma initiala (daca nu exista atunci se va afisa 0), 
--suma marita cu 15% în cazul în care exemplarul împrumutat apartine sectiunii „Matematica” 
--si cu 20% în cazul în care exemplarul împrumutat apartine sectiunii „Literatura”. 
--În plus se vor afisa si codul exemplarului împrumutat, titlul cartii, precum si numele sectiunii din care face parte.
--Datele vor fi ordonate în ordinea descrescatoare a sumelor marite. 

--În cadrul acestei cereri am utilizat fun?iile NVL ?i Decode, precum ?i clauza ORDER BY.

SELECT T.ID_TAXA, NVL(T.SUMA, 0) AS SUMA_INITIALA,
  NVL(T.SUMA * 
    DECODE(UPPER(S.NUME_SECTIUNE), 'MATEMATICA', 1.15, 'LITERATURA', 1.20, 1), 0) AS SUMA_MARITA,
  E.ID_EXEMPLAR, C.TITLU, S.NUME_SECTIUNE
FROM TAXA T
LEFT JOIN IMPRUMUT I ON T.ID_TAXA = I.ID_TAXA
LEFT JOIN EXEMPLAR E ON I.ID_EXEMPLAR = E.ID_EXEMPLAR
LEFT JOIN CATEGORIE CG ON E.ID_CATEGORIE = CG.ID_CATEGORIE
LEFT JOIN SECTIUNE S ON CG.ID_SECTIUNE = S.ID_SECTIUNE
LEFT JOIN CARTE C ON E.ID_CARTE = C.ID_CARTE
ORDER BY SUMA_MARITA DESC;

--CEREREA II
--Sa se afiseze id-ul, numele complet al cititorilor care au împrumutat carti din sectiunile literatura
--si matematica si le-au returnat în mai putin de 35 de zile, id-ul exemplarului împrumutat, titlurile cartilor împrumutate,
--durata împrumutului, precum si ziua din saptamâna în care le-au returnat.

--În cadrul acestei cereri am utilizat un bloc de cerere cu clauza WITH, subcereri sincronizate cu min 4 tabele,
--precum ?i func?ii pe ?iruri de caractere ?i date calendaristice (TO_CHAR, UPPER, CONCAT).

WITH DATE_CERUTE AS (
    SELECT I.ID_EXEMPLAR, I.ID_CITITOR, CT.TITLU, SEC.NUME_SECTIUNE,(I.DATA_RETURNARE-I.DATA_IMPRUMUT) AS DURATA_IMPRUMUT, I.DATA_RETURNARE,
    CONCAT (C.NUME, C.PRENUME) AS NUME_COMPLET
    FROM IMPRUMUT I
    JOIN CITITOR C ON I.ID_CITITOR=C.ID_CITITOR
    JOIN EXEMPLAR E ON I.ID_EXEMPLAR=E.ID_EXEMPLAR
    JOIN CARTE CT ON E.ID_CARTE=CT.ID_CARTE
    JOIN CATEGORIE CAT ON E.ID_CATEGORIE=CAT.ID_CATEGORIE
    JOIN SECTIUNE SEC ON CAT.ID_SECTIUNE=SEC.ID_SECTIUNE
    WHERE UPPER(SEC.NUME_SECTIUNE) IN ('LITERATURA', 'MATEMATICA') AND (I.DATA_RETURNARE - I.DATA_IMPRUMUT) <=35 
    )
SELECT D.ID_CITITOR, D.NUME_COMPLET, D.ID_EXEMPLAR, D.TITLU, D.DURATA_IMPRUMUT, TO_CHAR(D.DATA_RETURNARE, 'DAY') AS ZIUA_SAPTAMANII
FROM DATE_CERUTE D
ORDER BY D.NUME_COMPLET;

--CEREREA 2 - REFACUTA
--Sa se afiseze pentru cartile care au un numar de pagini mai mare decat media numarului de pagini a tuturor cartilor
--titlul concaternat cu numarul de pagini, numarul de autori ai cartii, nr de exemplare ale cartii precum si numarul de rezervari facute pentru aceste carti.
--Se vor lua in calcul doar cartile ale caror exemplare se gasesc in sectiunea de IT a bibliotecii. 
WITH DATE_CERUTE AS (SELECT AVG(NUMAR_PAGINI) AS MEDIE_PAGINI FROM CARTE)
SELECT CONCAT(C.TITLU, C.NUMAR_PAGINI) AS "TITLU SI NR.PAGINI",
    (SELECT COUNT(*)
     FROM SCRIERE S
     WHERE S.ID_CARTE=C.ID_CARTE) "NR_AUTORI",
     (SELECT COUNT(*)
     FROM EXEMPLAR E
     WHERE E.ID_CARTE=C.ID_CARTE) "NR_EXEMPLARE",
     (SELECT COUNT(*)
      FROM REZERVARE R
      WHERE R.ID_CARTE=C.ID_CARTE) "NR_REZERVARI"
FROM CARTE C, DATE_CERUTE D
WHERE C.NUMAR_PAGINI>D.MEDIE_PAGINI AND C.ID_CARTE IN
(SELECT E.ID_CARTE
 FROM EXEMPLAR E
 JOIN CATEGORIE CAT ON CAT.ID_CATEGORIE=E.ID_CATEGORIE
 JOIN SECTIUNE SEC ON SEC.ID_SECTIUNE=CAT.ID_SECTIUNE
 WHERE E.ID_CARTE=C.ID_CARTE AND UPPER(SEC.NUME_SECTIUNE)='IT');

--CEREREA III
--Sa se afiseze date despre edituri, precum si numarul total de împrumuturi pe care le-au avut exemplarele cartilor publicate de aceste edituri.
--Datele for fi afisate în ordinea descrescatoare numarului de împumuturi, de asemenea se vor omite editurile care au avut mai putin de 2 împrumuturi.

--În cadrul acestei cereri am utilizat func?ii de grup ?i filtrare la nivel de grupuri, precum ?i subcereri sincronizate în care intervin min 3 tabele.

SELECT E.id_editura, E.nume_editura,
    SUM(TOTAL_IMPRUMUTURI) AS numar_total_imprumuturi
FROM EDITURA E
JOIN (
    SELECT C.id_editura, COUNT(I.id_exemplar) AS TOTAL_IMPRUMUTURI
    FROM CARTE C
    LEFT JOIN EXEMPLAR EX ON C.id_carte = EX.id_carte
    LEFT JOIN IMPRUMUT I ON EX.id_exemplar = I.id_exemplar
    GROUP BY C.id_editura
) T ON E.id_editura = T.id_editura
GROUP BY E.id_editura, E.nume_editura
HAVING SUM(TOTAL_IMPRUMUTURI) > 2
ORDER BY numar_total_imprumuturi DESC;


--CEREREA IV 
--Sa se afiseze id-ul cartilor, titlurile cartilor precum si numarul de exemplare existente în biblioteca din fiecare carte,
--urmat de frecventa cartii („carte rara” daca numarul de exemplare e mai mic decât 3, „carte comuna” daca numarul de exemplare e cuprins 
--între 3 si 5, respectiv „carte populara” daca numarul de exemplare este mai mare de 5).

--În cadrul acestei cereri am uitilizat o subcere nesincronizata în clauza FROM, precum si o expresie CASE.

SELECT C.ID_CARTE, C.TITLU, EXP.NR "NR EXEMPLARE",
    CASE 
        WHEN EXP.NR < 3 THEN 'CARTE RARA'
        WHEN EXP.NR >= 3 AND EXP.NR < 5 THEN 'CARTE COMUNA'
        WHEN EXP.NR >= 5 THEN 'CARTE POPULARA'
    END AS "FRECVENTA CARTE"

FROM CARTE C, 
    (SELECT COUNT(*) NR, ID_CARTE
    FROM EXEMPLAR
    GROUP BY ID_CARTE
    HAVING COUNT(*) > 1 ) EXP
WHERE C.ID_CARTE = EXP.ID_CARTE;


--CEREREA V
--S? se afiseze id-ul, numele, prenumele si anul în care s-au înscris la biblioteca 
--al cititorilor care au împrumutat carti cu un num?r de pagini mai mare decât media num?rului de pagini al tuturor c?r?ilor disponibile.
--În plus se va afi?a pentru fiecare cititor ?i num?rul de astfel de împrumuturi.

--În cadrul acestei cereri am uitilizat subcereri nesincronizate cu minim 3 tabele precum ?i o func?ie pe date calendaristice(EXTRACT)
    
SELECT C.id_cititor, C.nume, C.prenume, COUNT(*) AS numar_imprumuturi, EXTRACT(YEAR FROM C.DATA_INSCRIERE) AS AN_INSCRIERE
FROM CITITOR C
INNER JOIN (
    SELECT I.id_cititor, E.id_exemplar
    FROM IMPRUMUT I
    INNER JOIN EXEMPLAR E ON I.id_exemplar = E.id_exemplar
    INNER JOIN CARTE CR ON E.id_carte = CR.id_carte
    WHERE CR.numar_pagini > (
        SELECT AVG(numar_pagini)
        FROM CARTE
    )
) IM ON C.id_cititor = IM.id_cititor
GROUP BY C.id_cititor, C.nume, C.prenume, EXTRACT(YEAR FROM C.DATA_INSCRIERE);

--13. OPERATII DE ACTUALIZARE SI DE SUPRIMARE A DATELOR UTILIZAND SUBCERERI

--1
--S? se actualizeze statusul c?r?ilor din tabela EXEMPLAR pentru acele exemplare
--care figureaz? ca împrumutate ?i înc? nereturnate în tabela ÎMPRUMUT.

UPDATE EXEMPLAR
SET status = (
  SELECT 
        CASE
            WHEN data_returnare IS NOT NULL THEN 'disponibil'
            ELSE 'imprumutat'
        END
  FROM IMPRUMUT
  WHERE id_exemplar = EXEMPLAR.id_exemplar
  ORDER BY data_imprumut DESC
  FETCH FIRST 1 ROW ONLY
)
WHERE id_exemplar IN (
  SELECT id_exemplar
  FROM IMPRUMUT
);

SELECT * FROM EXEMPLAR;

--2
--Modifica?i tabelul TAXA astfel încât pentru exemplarele împrumutate s? se calculeze suma pe care cititorii trebuie s? o pl?tesc?. 
--De asemenea schimba?i informa?iile despre statusul ?i data achit?rii taxei. Data achit?rii trebuie s? coincid? cu data 
--return?rii exemplarului din tabela ÎMPRUMUT, iar statusul va fi setat la "achitat".

UPDATE TAXA
SET suma = CASE
    WHEN EXISTS (
        SELECT 1
        FROM IMPRUMUT
        WHERE IMPRUMUT.id_taxa = TAXA.id_taxa
          AND data_imprumut IS NOT NULL
          AND data_returnare IS NOT NULL
    ) THEN
        CASE
            WHEN (
                SELECT data_returnare - data_imprumut
                FROM IMPRUMUT
                WHERE IMPRUMUT.id_taxa = TAXA.id_taxa
                ) > 30 THEN (
                    SELECT data_returnare - data_imprumut - 30
                    FROM IMPRUMUT
                    WHERE IMPRUMUT.id_taxa = TAXA.id_taxa
                )
            ELSE suma
        END
    ELSE suma
    END,
    data_achitare = (
        SELECT data_returnare
        FROM IMPRUMUT
        WHERE IMPRUMUT.id_taxa = TAXA.id_taxa
          AND data_imprumut IS NOT NULL
          AND data_returnare IS NOT NULL
    ),
    status = CASE
        WHEN EXISTS (
            SELECT 1
            FROM IMPRUMUT
            WHERE IMPRUMUT.id_taxa = TAXA.id_taxa
              AND data_returnare IS NOT NULL
        ) THEN 'achitat'
        ELSE status
    END
WHERE id_taxa IN (
    SELECT id_taxa
    FROM IMPRUMUT
    WHERE data_imprumut IS NOT NULL
      AND data_returnare IS NOT NULL
);

--3
--Crea?i o comand? SQL prin care s? se ?tearg? datele tuturor bibliotecarilor care nu se ocup? de nicio sec?iune a bibliotecii.

DELETE FROM BIBLIOTECAR B
WHERE B.id_bibliotecar NOT IN (
    SELECT S.id_bibliotecar
    FROM SECTIUNE S
);

--14. CREAREA UNEI VIZUALIZARI COMPLEXE
--Sa se afiseze pentru fiecare carte autorii si numarul de exemplare disponibile
CREATE VIEW DETALII_CARTI AS
(
    SELECT C.ID_CARTE, C.TITLU, A.NUME || ' ' || A.PRENUME AS "NUME_AUTOR", COUNT(E.ID_EXEMPLAR) AS "NUMAR_EXEMPLARE"
    FROM CARTE C
    JOIN SCRIERE S ON C.ID_CARTE=S.ID_CARTE
    JOIN AUTOR A ON S.ID_AUTOR=A.ID_AUTOR
    JOIN EXEMPLAR E ON C.ID_CARTE=E.ID_CARTE
    GROUP BY C.ID_CARTE, C.TITLU, A.NUME || ' ' || A.PRENUME
);
--Operatia LMD permisa
SELECT * FROM DETALII_CARTI ORDER BY "NUME_AUTOR";
--Operatie LMD nepermisa
DELETE FROM DETALII_CARTI
WHERE ID_CARTE=120;

--15.
--OUTER-JOIN
--Creati o condic? pentru starea împrumuturilor bibliotecii.
--În condic? vor fi afi?a?i cititorii bibliotecii care au împrumutat c?r?i, precum ?i titlurile c?r?ilor împrumutate
--urma?i de cititorii care nu au împrumutat nicio carte. 
--În condic? se vor ad?uga la final c?r?ile ale c?ror exemplare nu au fost împrumutate de niciun cititor.

SELECT DISTINCT C.ID_CITITOR, CONCAT(CONCAT(C.NUME, ' '), C.PRENUME) AS "CITITOR", C1.TITLU AS "TITLU CARTE", ED.NUME_EDITURA "TITLU_EDITURA"
FROM CITITOR C 
FULL OUTER JOIN IMPRUMUT I ON C.ID_CITITOR=I.ID_CITITOR
LEFT OUTER JOIN EXEMPLAR E ON E.ID_EXEMPLAR=I.ID_EXEMPLAR
FULL OUTER JOIN CARTE C1 ON E.ID_CARTE=C1.ID_CARTE
FULL OUTER JOIN EDITURA ED ON C1.ID_EDITURA=ED.ID_EDITURA
ORDER BY C.ID_CITITOR;

--OPERATORUL DIVISION
--Afisati informatii despre cartile ale caror exemplare se gasesc in toate sectiunile de care se ocupa bibliotecarul cu ID-ul 5.
SELECT C.ID_CARTE, C.TITLU
FROM CARTE C
WHERE NOT EXISTS (
    SELECT S.ID_SECTIUNE
    FROM SECTIUNE S
    WHERE S.ID_BIBLIOTECAR = 5
    AND NOT EXISTS (
        SELECT E.ID_EXEMPLAR
        FROM EXEMPLAR E
        JOIN CATEGORIE CAT ON E.ID_CATEGORIE=CAT.ID_CATEGORIE
        WHERE E.ID_CARTE = C.ID_CARTE
        AND CAT.ID_SECTIUNE = S.ID_SECTIUNE
    )
);

--ANALIZA TOP-N
--Sa se afiseze primele 3 carti cu cele mai multe exemplare din biblioteca
SELECT T.TITLU, T.NUMAR_EXEMPLARE
FROM (
  SELECT C.TITLU, COUNT(E.ID_EXEMPLAR) AS NUMAR_EXEMPLARE
  FROM CARTE C
  JOIN EXEMPLAR E ON C.ID_CARTE = E.ID_CARTE
  GROUP BY C.TITLU
  ORDER BY COUNT(E.ID_EXEMPLAR) DESC
) T
WHERE ROWNUM <= 3;


--16. OPTIMIZAREA UNEI CERERI
--Sa se afiseze titlul si numarul de pagini al cartilor scrise de autorul cu numele 
--"Popescu" si care au fost publicate la editura cu id-ul 1.
SELECT C.TITLU, NVL(TO_CHAR(C.NUMAR_PAGINI), 'NESPECIFICAT')
FROM CARTE C
JOIN SCRIERE S ON C.ID_CARTE=S.ID_CARTE
JOIN AUTOR A ON A.ID_AUTOR=S.ID_AUTOR
WHERE UPPER(A.NUME) = 'POPESCU' AND C.ID_EDITURA=1;

--19. OPTIMIZAREA UNOR CERERI FOLOSIND INDEXARE

--CEREREA I
--Sa se afiseze eficient autorul cu numele 'Popescu Radu'
CREATE INDEX IDX_NUME_AUTOR
ON AUTOR (NUME, PRENUME);
SELECT * FROM AUTOR
WHERE NUME='Popescu' AND PRENUME='Radu';

--CEREREA II
--Sa se afiseze eficient cartile publicate intr-un anumit an;
CREATE INDEX IDX_AN_PUBLICARE ON CARTE (AN_PUBLICARE);
SELECT * FROM CARTE WHERE AN_PUBLICARE = 2018;