curl http://localhost:8080/api/todos -X POST -d '{"description": "feed the mutts"}'

curl http://localhost:8080/api/todos/incomplete

curl http://localhost:8080/api/todos/complete/1 -X PATCH

curl http://localhost:8080/api/todos/2 -X PATCH -d '{"description": "all good!"}'

curl http://localhost:8080/api/todos/completed

