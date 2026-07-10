package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/Innocent9712/much-to-do/Server/MuchToDo/internal/auth"
	"github.com/Innocent9712/much-to-do/Server/MuchToDo/internal/cache"
	"github.com/Innocent9712/much-to-do/Server/MuchToDo/internal/config"
)

// TodoHandler handles todo-related routes.
type TodoHandler struct {
	collection *mongo.Collection
}

func NewTodoHandler(collection *mongo.Collection) *TodoHandler {
	return &TodoHandler{collection: collection}
}

func (h *TodoHandler) GetTodos(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"todos": []interface{}{}})
}

func (h *TodoHandler) CreateTodo(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"message": "todo created"})
}

func (h *TodoHandler) GetTodo(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"todo": nil})
}

func (h *TodoHandler) UpdateTodo(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "todo updated"})
}

func (h *TodoHandler) DeleteTodo(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "todo deleted"})
}

// UserHandler handles user-related routes.
type UserHandler struct {
	userCollection *mongo.Collection
	todoCollection *mongo.Collection
	tokenSvc       *auth.TokenService
	cacheSvc       cache.Cache
	db             *mongo.Client
	cfg            config.Config
}

func NewUserHandler(
	userCollection *mongo.Collection,
	todoCollection *mongo.Collection,
	tokenSvc *auth.TokenService,
	cacheSvc cache.Cache,
	db *mongo.Client,
	cfg config.Config,
) *UserHandler {
	return &UserHandler{
		userCollection: userCollection,
		todoCollection: todoCollection,
		tokenSvc:       tokenSvc,
		cacheSvc:       cacheSvc,
		db:             db,
		cfg:            cfg,
	}
}

func (h *UserHandler) Register(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"message": "user registered"})
}

func (h *UserHandler) Login(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"token": ""})
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"user": nil})
}

func (h *UserHandler) DeleteAccount(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "account deleted"})
}

// HealthHandler handles health-check routes.
type HealthHandler struct {
	db          *mongo.Client
	cacheSvc    cache.Cache
	enableCache bool
}

func NewHealthHandler(db *mongo.Client, cacheSvc cache.Cache, enableCache bool) *HealthHandler {
	return &HealthHandler{db: db, cacheSvc: cacheSvc, enableCache: enableCache}
}

func (h *HealthHandler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
