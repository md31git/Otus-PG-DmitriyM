## 1.развернуть виртуальную машину любым удобным способом и поставить на неё PostgreSQL 15 любым способом
Исходные данные:
* Виртуальная машина =  WSL (Ubuntu 22.04.1)
* PostgreSQL =  14.12
* Процессор = 8 ядер
* ОЗУ = 8Гб
* Диск = HDD

## 2. Настройки по умолчанию и тест производительности 
Настройи по умолчанию PG:
name                        |value    |
----------------------------+---------+
checkpoint_completion_target|0.9      |
checkpoint_timeout          |300s     |
effective_cache_size        |5242888kB|
huge_pages                  |try      |
maintenance_work_mem        |65536kB  |
max_connections             |100      |
max_parallel_workers        |8        |
max_wal_size                |1024MB   |
max_worker_processes        |8        |
min_wal_size                |80MB     |
shared_buffers              |163848kB |
synchronous_commit          |on       |
wal_buffers                 |5128kB   |
wal_level                   |replica  |
work_mem                    |4096kB   |

Запуск 




## 2.настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины
## 3.нагрузить кластер через утилиту через утилиту pgbench (https://postgrespro.ru/docs/postgrespro/14/pgbench)
## 4.написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему
