package cache

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Innocent9712/much-to-do/Server/MuchToDo/internal/config"
	"github.com/redis/go-redis/v9"
)

type Cache interface {
	Get(ctx context.Context, key string, dest interface{}) error
	Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error
	SetMany(ctx context.Context, items map[string]interface{}, ttl time.Duration) error
	Delete(ctx context.Context, key string) error
}

type redisCache struct {
	client *redis.Client
}

func NewCacheService(cfg config.Config) Cache {
	client := redis.NewClient(&redis.Options{
		Addr:     cfg.RedisAddr,
		Password: cfg.RedisPassword,
	})
	return &redisCache{client: client}
}

func (r *redisCache) Get(ctx context.Context, key string, dest interface{}) error {
	val, err := r.client.Get(ctx, key).Result()
	if err != nil {
		return err
	}
	return json.Unmarshal([]byte(val), dest)
}

func (r *redisCache) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	b, err := json.Marshal(value)
	if err != nil {
		return err
	}
	return r.client.Set(ctx, key, b, ttl).Err()
}

func (r *redisCache) SetMany(ctx context.Context, items map[string]interface{}, ttl time.Duration) error {
	pipe := r.client.Pipeline()
	for k, v := range items {
		b, err := json.Marshal(v)
		if err != nil {
			return err
		}
		pipe.Set(ctx, k, b, ttl)
	}
	_, err := pipe.Exec(ctx)
	return err
}

func (r *redisCache) Delete(ctx context.Context, key string) error {
	return r.client.Del(ctx, key).Err()
}
