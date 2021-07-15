package main

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"strconv"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"

	//_ "github.com/go-sql-driver/mysql"
	"github.com/jinzhu/gorm"
	"gorm.io/driver/sqlite"
	_ "github.com/jinzhu/gorm/dialects/mysql"
	"github.com/rs/cors"
)

//var db, _ = gorm.Open("mysql", "root:root@/todolist?charset=utf8&parseTime=True&loc=Local")
var db, _ = gorm.Open(sqlite.Open("file::memory:?cache=shared"))
type TodoItemModel struct {
	Id          int `gorm:"primary_key"`
	Description string
	Completed   bool
}

func Healthz(w http.ResponseWriter, r *http.Request) {
	log.Info("API Health is OK")
	w.Header().Set("Content-Type", "application/json")
	io.WriteString(w, `{"alive": true}`)
}

func init() {
	log.SetFormatter(&log.TextFormatter{})
	log.SetReportCaller(true)
}

func CreateItem(w http.ResponseWriter, r *http.Request) {
	description := r.FormValue("description")
	log.WithFields(log.Fields{"description": description}).Info("Add new TodoItem. Saving to database.")
	todo := &TodoItemModel{Description: description, Completed: false}
	db.Create(&todo)
	result := db.Last(&todo)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result.Value)
}

func UpdateItem(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	err := GetItemById(id)
	if !err {
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{"updated: false, "error": "Record Not Found"}`)
	} else {
		completed, _ := strconv.ParseBool(r.FormValue("completed"))
		log.WithFields(log.Fields{"Id": id, "Completed": completed}).Info("Updating TodoItem")
		todo := &TodoItemModel{}
		db.First(&todo, id)
		todo.Completed = completed
		db.Save(&todo)
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{"updated": true}`)
	}
}

func DeleteItem(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	err := GetItemById(id)
	if !err {
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{"deleted": false, "error": "Record Not Found"}`)
	} else {
		log.WithFields(log.Fields{"Id": id}).Info("Deelte TodoItem")
		todo := &TodoItemModel{}
		db.First(&todo, id)
		db.Delete(&todo)
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{"deleted": true}`)

	}
}

func GetItemById(Id int) bool {
	todo := &TodoItemModel{}
	result := db.First(&todo, Id)
	if result.Error != nil {
		log.Warn("Todo item not found in database")
		return false
	}
	return true
}

func GetCompletedItems(w http.ResponseWriter, r *http.Request) {
	log.Info("Get completed TodoItems")
	completedTodoItems := GetTodoItems(true)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(completedTodoItems)
}

func GetIncompleteItems(w http.ResponseWriter, r *http.Request) {
	log.Info("Get Incomplete TodoItems")
	IncompleteTodoItems := GetTodoItems(false)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(IncompleteTodoItems)
}

func GetTodoItems(completed bool) interface{} {
	var todos []TodoItemModel
	TodoItems := db.Where("completed = ?", completed).Find(&todos).Value
	return TodoItems
}

func main() {
	defer db.Close()
	db.Debug().DropTableIfExists(&TodoItemModel{})
	db.Debug().AutoMigrate(&TodoItemModel{})

	listenAddr := ":8080"
	if val, ok := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT"); ok {
		listenAddr = ":" + val
	}
	log.Info("Starting ToDoList API Server")
	router := mux.NewRouter()
	router.HandleFunc("/healthz", Healthz).Methods("GET")
	router.HandleFunc("/completedItems", GetCompletedItems).Methods("GET")
	router.HandleFunc("/incompleteItems", GetIncompleteItems).Methods("GET")
	router.HandleFunc("/todoItem", CreateItem).Methods("POST")
	router.HandleFunc("/todoItem/{id}", UpdateItem).Methods("POST")
	router.HandleFunc("/todoItem/{id}", DeleteItem).Methods("DELETE")
	handler := cors.New(cors.Options{
		AllowedMethods: []string{"GET", "POST", "DELETE", "PATCH", "OPTIONS"},
	}).Handler(router)

	http.ListenAndServe(listenAddr, handler)
}
