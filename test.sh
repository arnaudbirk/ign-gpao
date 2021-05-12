echo Ajouter un projet
curl -X PUT "http://localhost:8080/api/project" -H "Content-Type: application/json" -d "{\"projects\":[{\"name\":\"Chantier 1\",\"jobs\":[{\"name\":\"jobs 1\",\"command\":\"touch file1\"},{\"name\":\"jobs 2\",\"command\":\"touch file2\"},{\"name\":\"jobs 3\",\"command\":\"touch file3\",\"deps\":[{\"id\":0},{\"id\":1}]}]},{\"name\":\"Chantier 2\",\"jobs\":[{\"name\":\"jobs 1\",\"command\":\"touch file1\"}],\"deps\":[{\"id\":0}]}]}"
echo creation du modele de resultat
echo '[{"id":1,"name":"Chantier 1","status":"done"},{"id":2,"name":"Chantier 2","status":"done"}]' > resultat.json
echo recuperation des projets et comparaison
while ! curl -X GET "http://localhost:8080/api/projects" | diff --ignore-all-space resultat.json -; do echo on attend; sleep 1; done; echo ok
echo Fin

