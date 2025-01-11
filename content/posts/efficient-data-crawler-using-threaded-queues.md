---
author: Johan Hanekom
title: "Python Threaded Queues: Building a Data Crawler for 70,000+ API Calls"
date: 2025-01-11
tags:
  - Python
draft: "false"
---
![architecture](/images/threaded-workers-arch.svg)
## My plan of action

Ever since I read the documentation for Python's [threaded queue](https://docs.python.org/3/library/queue.html#queue.Queue.join), I've been wondering: "Can I use this to build a really efficient web crawler?" The answer is yes!  

For today’s experiment, our guinea pig will be **Cars.co.za**! Cars.co.za is a South African automotive website that helps people buy and sell new and used cars.  

When you navigate to [cars.co.za](https://www.cars.co.za) and click on "Search" without specifying any filters, you're directed to a results page containing the website's entire catalog of cars. Interestingly, all the results are returned to the user.  

By opening the developer tools in the browser (press `Ctrl` + `Shift` + `C`), we can observe a `GET` request being made to the website's backend. This request retrieves the car listings. Let's break it down!

```
GET https://api.cars.co.za/fw/public/v3/vehicle?page[offset]=0&page[limit]=20&include_featured=true&sort[date]=desc
```

with the following response:

```json
{
    "meta": {
        "total": 71290,
        "totalPages": 3564,
        "currentPage": 0
    },
    "links": {
        "self": "https:\/\/api.cars.co.za\/fw\/public\/v3\/vehicle?page%5Boffset%5D=0&page%5Blimit%5D=20&include_featured=true&sort%5Bdate%5D=desc",
        "next": "https:\/\/api.cars.co.za\/fw\/public\/v3\/vehicle?page%5Boffset%5D=20&page%5Blimit%5D=20&include_featured=true&sort%5Bdate%5D=desc",
        "last": "https:\/\/api.cars.co.za\/fw\/public\/v3\/vehicle?page%5Boffset%5D=71270&page%5Blimit%5D=20&include_featured=true&sort%5Bdate%5D=desc"
    },
    "data": [
        {
            "type": "vehicle",
            "id": "9966395",
            "attributes": {
	            ...
                "code": "pJyZp5uopZ0=",
                "year": 2017,
                "website_url": "https:\/\/www.cars.co.za\/for-sale\/used\/2017-Audi-A4-1.4-TFSI-Sport-Auto-Gauteng-Pretoria\/9966395\/"
                ...
            }
        }
    ]
}
```

Here, we can see:  
- Useful metadata, such as the total number of cars in their catalog and the current page number.  
- Links to the current page, next page, and last page.  
- Data for the first 10 cars displayed in the search results.  

While several attributes are available for each listing, we don’t get all the specifications here. Those details are only accessible when viewing the listing itself. Clicking on the link in the `website_url` field triggers another `GET` request to the backend.

```
GET https://api.cars.co.za/fw/public/v2/specs/pJyZp5uopZ0=/2017
```

which returns

```json
{
  "data": [
    [
      {
        "title": "Summary",
        "attrs": [
          {
            "label": "Seats quantity",
            "value": "5"
          },
          {
            "label": "0-100Kph",
            "value": "8.5 s"
          },
          {
            "label": "Average Fuel Economy",
            "value": "5.1 l/100km"
          },
          {
            "label": "Power Maximum Total",
            "value": "110 kW"
          }
        ]
      }
    ]
  ]
}
```


And now we get all of our juicy car specifications! 🎉  

To retrieve all the data for every listing on Cars.co.za, we need two types of API calls:  
1. **Pagination calls**: These provide initial data for each listing, including the link to fetch the listing's detailed specifications.  
2. **Specification calls**: These fetch the full specifications for each listing.  

Let’s look at one of the [examples](https://docs.python.org/3/library/queue.html#queue.Queue.join) in Python's documentation on how to use threaded queues:  

```python
import threading
import queue

q = queue.Queue()

def worker():
    while True:
        item = q.get()
        print(f'Working on {item}')
        print(f'Finished {item}')
        q.task_done()

# Turn on the worker thread.
threading.Thread(target=worker, daemon=True).start()

# Send thirty task requests to the worker.
for item in range(30):
    q.put(item)

# Block until all tasks are done.
q.join()
print('All work completed')
````

Here’s how it works:
- We define a new queue class: `q = queue.Queue()`
- **Workers** are functions that perform tasks on items in the queue. These workers run continuously in the background using an infinite `while` loop (enabled by `daemon=True` in `threading.Thread`).
- The `q.put(item)` method adds new items to the queue. Once an item is added, a worker fetches it using `q.get()` and performs the task. By default, `.get()` blocks the code until an item is available.
- The `q.join()` method ensures the program waits until all items in the queue have been processed.

We’ll use a similar design pattern for our script, but with **three types of workers**:
1. **Pagination workers**: These will navigate through the search results.
2. **Specification workers**: These will fetch detailed specifications for each listing.
3. **Backup workers**: These will save the results frequently to a JSON file.

**Why the Backup Worker?**

From past experience working on scrapers, I’ve learned a valuable lesson: **always save your data regularly**. Scrapers can suddenly fail due to critical errors, so having backups ensures you don’t lose everything. Saving data both in memory during scraping and on your PC is crucial.

As the saying goes:

> "Two is one, and one is none."

If you have two files, you effectively have one. If you have only one file, you effectively have none! **Make backups!**
## Code Breakdown  

I won't dive too deeply into the code but will highlight the interesting parts! You can find the source code [here](https://github.com/Johandielangman/cars.co.za-scraper/blob/main/scraper.py).  

### Dataclasses  

I’ve been trying to get into the habit of using dataclasses more often. One of the main benefits is that my IDE provides autocompletion for nested dataclasses. For example, when I type `foo.bar.zar`, each level is suggested by the autocompleter. This is much nicer than memorizing dictionary keys or scrolling through the code to understand how to access the data in a dictionary.  

In this project, I’ve used two dataclasses:  

1. **`SearchPageResponse`**: Stores the response returned from the search page.  
   - **Attributes**:  
     1. `links` (type: `SearchPageLinks`)  
     2. `data` (type: `List[Dict]`)  
     3. `current_page` (type: `int`)  
     4. `total_pages` (type: `int`)  

2. **`SearchPageLinks`**: Stores all the pagination links for crawling to the next page.  
   - **Attributes**:  
     1. `self` (type: `str`)  
     2. `first` (type: `str`)  
     3. `next` (type: `str`)  
     4. `prev` (type: `str`)  
     5. `last` (type: `str`)  

These dataclasses are defined as follows:  

```python
@dataclass
class SearchPageLinks:
    self: str = field(default="")
    first: str = field(default="")
    next: str = field(default="")
    prev: str = field(default="")
    last: str = field(default="")


@dataclass
class SearchPageResponse:
    links: SearchPageLinks
    data: List[Dict]
    current_page: int
    total_pages: int

    def get_car_data(self) -> Generator:
        for listing in self.data:
            car_attrs: Dict = listing['attributes']
            yield f"{CAR_DATA_LINK}/{car_attrs['code']}/{car_attrs['year']}", car_attrs
````

The great thing about dataclasses is that you can define methods like in regular classes. For example, I added a generator method, `get_car_data`, which returns the link to a car's specifications along with the attributes listed on the search results.

**Why Type Hinting?**

Over the years, I’ve received criticism for my type hinting since Python is a loosely typed language. However, type hints are incredibly helpful when revisiting old code. Instead of digging through the entire codebase to understand a function’s return value, type hints make it easy to use the function without second-guessing.

Yes, Python doesn’t enforce type safety, but type hints improve readability and serve as a habit that transitions well to strongly typed languages like Go. Hate it or love it -- I find them invaluable.

![architecture](/images/be_like_bill.jpg)
### Making the API Call and Creating a Dataclass

Since many websites are picky about requests, I use the `requests.Session` class to make API calls. This allows me to set custom headers like a user agent, origin, and referrer. If I start running into rate limiting, I can mount a *Retry* class to the session. I’ve defined a `new_session` function so each worker has its own session.

```python
def new_session() -> requests.Session:
    s: requests.Session = requests.Session()
    s.headers.update({
        'User-Agent': (
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/130.0.0.0 Safari/537.36 OPR/115.0.0.0'
        ),
        'Origin': 'https://www.cars.co.za',
        'Referer': 'https://www.cars.co.za/'
    })
    return s
```

Now, I can create a fresh session for API calls:

```python
s: requests.Session = new_session()
try:
    result: requests.Response = s.get(link)
    result.raise_for_status()
    response: SearchPageResponse = new_search_page_response(result.json())
    for car_data_link, attrs in response.get_car_data():
        car_data_request_queue.put((car_data_link, attrs))
    search_page_request_queue.put(response.links.next)
    _i: str = f"[{response.current_page:<5}/{response.total_pages:<5}]"
except Exception as e:
    logger.error(f"{_i} {e}")
```

The `new_search_page_response` function handles the transformation of `result.json()` into a `SearchPageResponse`. This code also demonstrates how I use the generator method to populate the `car_data_request_queue` for the specification worker and add the next search page link to the `search_page_request_queue` for the pagination worker.
### Loguru: Logging Made Easy

I’ve been using [loguru](https://github.com/Delgan/loguru) for a while now, and it’s a [game-changer](https://www.michiganpublic.org/education/2025-01-01/cringe-game-changer-and-skibidi-top-this-years-lssu-list-of-banned-words-and-phrases). It’s an effortless way to set up a professional-looking logger without wrestling with Python's standard logging library.

Here’s a quick demo of what makes Loguru awesome (straight from their [docs](https://github.com/Delgan/loguru)):

![Loguru Demo](https://raw.githubusercontent.com/Delgan/loguru/master/docs/_static/img/demo.gif)

I use `logger.debug` for most logs. However, when dealing with thousands of logs, scrolling through all of them is impractical. That’s why I create a log file where I set the log level to `INFO`, so only essential logs are saved.

```python
logger.add(
    f"{os.path.join(RESULT_FOLDER_PATH, FILENAME)}.log",
    level="INFO"
)
logger.debug("I will be displayed in the console, but will NOT be saved to the *.log file")
logger.info("I will be displayed in the console AND saved to the *.log file")
```

With this setup, I can troubleshoot efficiently without overloading my log files.

## The Three Workers

### 1. Pagination Worker

This worker handles crawling through the pagination links and sending car data links to the next worker via a queue.

```python
def search_page_worker(worker_id: int) -> None:
    _p: str = create_logger_prefix("SEARCH_PAGE_WORKER", worker_id)

    logger.info(f"{_p} Starting Worker {worker_id}")
    while True:
        link: str = search_page_request_queue.get()
        s: requests.Session = new_session()

        # ========// WORK //=========
        _i: str = ""
        try:
            result: requests.Response = s.get(link)
            result.raise_for_status()
            response: SearchPageResponse = new_search_page_response(result.json())
            for car_data_link, attrs in response.get_car_data():
                car_data_request_queue.put((car_data_link, attrs))
            search_page_request_queue.put(response.links.next)
            _i: str = f"[{response.current_page:<5}/{response.total_pages:<5}]"
        except Exception as e:
            logger.error(f"{_p} {e}")
        # ===========================

        logger.debug(f"{_p}{_i} Finished {link}")
        search_page_request_queue.task_done()
```

#### Key Features

- **Queue-Based Workflow**: The worker pulls links from `search_page_request_queue` and processes them.
- **Error Handling**: If a request fails, it logs the error and continues without halting the worker.
- **Retry Logic**: Although not implemented here, you could add a retry mechanism to handle transient server errors.

### 2. Specification Worker

This worker fetches detailed specification data for each car and prepares it for saving by the backup worker.

```python
def car_data_worker(worker_id: int) -> None:
    _p: str = create_logger_prefix("CAR_DATA_WORKER", worker_id)
    logger.info(f"{_p} Starting Worker {worker_id}")
    while True:
        link, car_attrs = car_data_request_queue.get()
        s: requests.Session = new_session()

        # ========// WORK //=========
        try:
            result: requests.Response = s.get(link)
            result.raise_for_status()
            car_specs: List[Dict] = result.json()['data'][0]
            car_data_result_queue.put({
                "car_attrs": car_attrs,
                "car_specs": car_specs
            })
        except Exception as e:
            logger.error(f"{_p} {e}")
        # ===========================

        logger.debug(f"{_p} Finished {link}")
        car_data_request_queue.task_done()
```

#### Key Features

- **Data Merging**: Combines the car’s search page attributes (`car_attrs`) with its detailed specifications (`car_specs`) into a single dictionary.
- **Error Logging**: Similar to the pagination worker, it logs errors without interrupting the process.

### 3. Backup Worker

This worker ensures that data is saved periodically, reducing the risk of losing progress if the script fails during execution.

```python
def save_car_data_worker(worker_id: int) -> None:
    _p: str = create_logger_prefix("RESULTS", worker_id)
    logger.info(f"{_p} Starting Worker {worker_id}")

    # For batch processing
    batch: List[Dict] = []
    last_save_time: float = time.time()

    while True:
        try:
            data: Dict = car_data_result_queue.get(timeout=TIMEOUT_SECONDS)
            batch.append(data)

            if (
                len(batch) >= BATCH_SIZE or
                (time.time() - last_save_time) >= TIMEOUT_SECONDS
            ):
                process_batch(
                    batch=batch,
                    filename=FILENAME,
                    prefix=_p
                )
                last_save_time = time.time()

            car_data_result_queue.task_done()

        except queue.Empty:
            process_batch(
                batch=batch,
                filename=FILENAME,
                prefix=_p
            )
            last_save_time = time.time()
```

#### Key Features

- **Batching**: Saves data either when the batch size (`BATCH_SIZE`) is reached or after a specified timeout (`TIMEOUT_SECONDS`).
- **Timeout Mechanism**: Uses the `.get(timeout=TIMEOUT_SECONDS)` feature to ensure the worker doesn’t block indefinitely.

#### Writing Data Safely

Since we overwrite the same `json` file, we first create a "staging" file before marking it as the final file. This approach ensures that large JSON files are written safely, as the writing process can take time. We don’t want to delete our existing, intact file until the new file is fully written. The steps are as follows:

1. Start with an existing file named `results.json`.
2. Write the new data to a temporary file called `_results.json`.
3. Once `_results.json` has been successfully written, delete `results.json` and rename `_results.json` to `results.json`.

Here is the code:

```python
def save_batch_to_file(
    filename: str,
    batch: List[Dict],
    prefix: str
) -> bool:
    try:
        existing_data = load_existing_data(filename, prefix)
        existing_data.extend(batch)

        temp_filename: str = os.path.join(RESULT_FOLDER_PATH, f"_{filename}")
        final_filename: str = os.path.join(RESULT_FOLDER_PATH, filename)

        with open(temp_filename, 'w') as f:
            json.dump(existing_data, f)
        logger.debug(f"{prefix} Batch of {len(batch)} items saved to {filename}")

        # Rename files
        if os.path.exists(final_filename):
            os.remove(final_filename)
        time.sleep(1)
        os.rename(temp_filename, final_filename)

        return True

    except Exception as e:
        logger.error(f"{prefix} Error saving batch: {e}")
        return False
```

## Thanks for reading!

Thank you for reading! Or, if you were just browsing through the code and images... I’d love to hear your thoughts! Feel free to share any feedback!