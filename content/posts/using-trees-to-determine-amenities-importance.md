---
author: Johan Hanekom
title: Using Trees to Determine What Amenities Drive Airbnb Prices
date: 2025-05-24
tags:
  - Analysis
  - R
draft: "true"
---
![thumbnail](/images/airbnb-thumbnail.png)

Is everything in an Airbnb listing considered a competitive advantage these days? Just look at the [listing](https://www.airbnb.co.za/rooms/6083797?locale=en&_set_bev_on_new_domain=1747764944_EAYTQ3YTdhN2VkMz&source_impression_id=p3_1747765191_P3NqqkpoHvPQvjC7&check_in=2026-04-04&guests=1&adults=1&check_out=2026-04-06) in this thumbnail. It has 45 amenities on it's listing. Some of them just feel ridiculous: Toaster, Hangers and Hot Water. I really hope most places have hot water. Is saying you have a toaster really a selling point? "We need to look for a listing that has a toaster. I bought a really nice loaf of bread the other day and it *HAS* to be toasted." Or do hosts simply add these amenities to drive up their price?

That is what we'll be looking at today. I want to see if certain amenities drive your listing's price. Maybe the fact that there is just a number is the real driver for a higher price. 

The data I'll be using is data from Cape Town. I have to try to build this model by also removing a very strong bias: location, location, location. The listing closer to the Waterfront will be much more expensive than the listings in CBP. 

![expensive-vs-cheap](/images/expensive-vs-cheap.png)

## Getting the Data... and cleaning it...

The data comes from [Inside Airbnb](https://insideairbnb.com/explore/). They provide the data on several listings across the world. They also have some data about the listings in Cape Town.

I can just go to their [get the data](https://insideairbnb.com/get-the-data/) page and download the [listings](https://data.insideairbnb.com/south-africa/wc/cape-town/2025-03-19/data/listings.csv.gz) data as of 19 March 2025. Considering it's 24 May right now, the data is a bit old, but still reasonably new.

Now I can read in the data and clean some of the column names:

```R
listings_raw <- read_csv(file.path(DATA_RAW_DIR, "listings.csv.gz")) %>%
  as_tibble() %>%
  janitor::clean_names()
```

Now if I run `listings_raw %>% glimpse()`, we can get a quick view of all the data:

```
Rows: 25,882
Columns: 79
$ id                                           <dbl> 3191, 15077, 15480, 18499, 19384, 20125, 20263, 298622, 357793, 15007, 150…
$ listing_url                                  <chr> "https://www.airbnb.com/rooms/3191", "https://www.airbnb.com/rooms/15077",…
$ scrape_id                                    <dbl> 2.025032e+13, 2.025032e+13, 2.025032e+13, 2.025032e+13, 2.025032e+13, 2.02…
$ last_scraped                                 <date> 2025-03-20, 2025-03-20, 2025-03-20, 2025-03-21, 2025-03-20, 2025-03-21, 2…
$ source                                       <chr> "city scrape", "city scrape", "city scrape", "previous scrape", "city scra…
$ name                                         <chr> "Malleson Garden Cottage", "Relaxed beach living in style", "In hip design…
$ description                                  <chr> "This is a lovely, separate, self-catering cottage set apart in the garden…
$ neighborhood_overview                        <chr> "Mowbray is on the Southern Suburbs line, 6km (4 train stops) from the Cit…
$ picture_url                                  <chr> "https://a0.muscache.com/pictures/697022/385407b5_original.jpg", "https://…
$ host_id                                      <dbl> 3754, 59342, 60443, 71221, 73764, 76161, 837661, 1539169, 1802190, 59072, …
$ host_url                                     <chr> "https://www.airbnb.com/users/show/3754", "https://www.airbnb.com/users/sh…
$ host_name                                    <chr> "Brigitte", "Georg", "Jean", "Abe", "Ingrid", "Debbie", "Daniel", "Diane",…
$ host_since                                   <date> 2008-10-21, 2009-12-02, 2009-12-06, 2010-01-17, 2010-01-26, 2010-02-01, 2…
$ host_location                                <chr> "Cape Town, South Africa", "Gibraltar", "Betty's Bay, South Africa", "Cape…
$ host_about                                   <chr> "I'm single and love to travel and meeting people from all corners of the …
$ host_response_time                           <chr> "within an hour", "within a few hours", "a few days or more", "N/A", "N/A"…
$ host_response_rate                           <chr> "100%", "100%", "0%", "N/A", "N/A", "N/A", "100%", "90%", "100%", "100%", …
$ host_acceptance_rate                         <chr> "100%", "83%", "13%", "N/A", "0%", "N/A", "80%", "47%", "96%", "91%", "30%…
$ host_is_superhost                            <lgl> TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, F…
$ host_thumbnail_url                           <chr> "https://a0.muscache.com/im/users/3754/profile_pic/1259095773/original.jpg…
$ host_picture_url                             <chr> "https://a0.muscache.com/im/users/3754/profile_pic/1259095773/original.jpg…
$ host_neighbourhood                           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
$ host_listings_count                          <dbl> 1, 7, 2, 1, 1, 1, 2, 1, 1, 7, 8, 1, 1, 7, 3, 5, 1, 1, 1, 1, 1, 3, 2, 2, 2,…
$ host_total_listings_count                    <dbl> 2, 7, 2, 1, 1, 1, 2, 2, 3, 18, 20, 1, 2, 7, 3, 5, 1, 1, 1, 1, 2, 4, 2, 2, …
$ host_verifications                           <chr> "['email', 'phone', 'work_email']", "['email', 'phone']", "['email', 'phon…
$ host_has_profile_pic                         <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, T…
$ host_identity_verified                       <lgl> TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, …
$ neighbourhood                                <chr> "Southern Suburbs, Western Cape, South Africa", "Tableview - Sunset Beach,…
$ neighbourhood_cleansed                       <chr> "Ward 57", "Ward 4", "Ward 115", "Ward 2", "Ward 77", "Ward 73", "Ward 64"…
$ neighbourhood_group_cleansed                 <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
$ latitude                                     <dbl> -33.94762, -33.85836, -33.92876, -33.89034, -33.92674, -34.02590, -34.1364…
$ longitude                                    <dbl> 18.47599, 18.49038, 18.42247, 18.58852, 18.40597, 18.48428, 18.41994, 18.4…
$ property_type                                <chr> "Entire home", "Private room in rental unit", "Entire rental unit", "Priva…
$ room_type                                    <chr> "Entire home/apt", "Private room", "Entire home/apt", "Private room", "Ent…
$ accommodates                                 <dbl> 2, 2, 2, 6, 3, 2, 6, 4, 4, 6, 6, 2, 3, 15, 2, 2, 4, 2, 8, 1, 6, 2, 4, 3, 5…
$ bathrooms                                    <dbl> 1.0, 1.0, 1.0, NA, 1.5, NA, 3.0, 1.0, 2.0, 3.0, 2.0, 1.0, NA, 7.5, 1.0, 1.…
$ bathrooms_text                               <chr> "1 bath", "1 private bath", "1 bath", "2 baths", "1.5 baths", "1 bath", "3…
$ bedrooms                                     <dbl> 1, 1, 1, NA, 2, NA, 3, 1, 2, 3, 3, 1, 2, 7, 1, 1, NA, NA, 4, NA, 3, 1, 2, …
$ beds                                         <dbl> 1, 2, 1, NA, 2, NA, 3, 5, 4, 4, 5, 1, NA, 7, 1, 1, NA, NA, NA, NA, 5, 1, N…
$ amenities                                    <chr> "[\"Refrigerator\", \"Oven\", \"Hot water\", \"Wifi\", \"Kitchen\", \"Cook…
$ price                                        <chr> "$674.00", "$1,818.00", "$621.00", NA, "$1,400.00", NA, "$7,000.00", "$1,3…
$ minimum_nights                               <dbl> 3, 2, 30, 7, 1, 1, 5, 2, 4, 2, 4, 14, 3, 4, 2, 2, 2, 7, 7, 3, 7, 2, 21, 28…
$ maximum_nights                               <dbl> 730, 1125, 1125, 730, 1125, 730, 1125, 180, 90, 120, 730, 30, 730, 730, 60…
$ minimum_minimum_nights                       <dbl> 1, 2, 30, 7, 1, 1, 5, 2, 4, 2, 4, 14, 3, 3, 2, 2, 2, 7, 7, 3, 6, 2, 14, 1,…
$ maximum_minimum_nights                       <dbl> 3, 6, 30, 7, 1, 1, 10, 2, 4, 2, 4, 14, 3, 14, 2, 2, 2, 7, 7, 3, 7, 5, 14, …
$ minimum_maximum_nights                       <dbl> 730, 1125, 1125, 730, 1125, 730, 1125, 180, 90, 1125, 730, 30, 730, 730, 6…
$ maximum_maximum_nights                       <dbl> 730, 1125, 1125, 730, 1125, 730, 1125, 180, 90, 1125, 730, 30, 730, 730, 6…
$ minimum_nights_avg_ntm                       <dbl> 3.0, 3.7, 30.0, 7.0, 1.0, 1.0, 7.2, 2.0, 4.0, 2.0, 4.0, 14.0, 3.0, 5.0, 2.…
$ maximum_nights_avg_ntm                       <dbl> 730.0, 1125.0, 1125.0, 730.0, 1125.0, 730.0, 1125.0, 180.0, 90.0, 1125.0, …
$ calendar_updated                             <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
$ has_availability                             <lgl> TRUE, TRUE, TRUE, NA, TRUE, NA, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, NA, TR…
$ availability_30                              <dbl> 14, 29, 15, 0, 0, 0, 0, 5, 14, 15, 29, 30, 0, 11, 3, 4, 0, 0, 0, 0, 0, 11,…
$ availability_60                              <dbl> 14, 45, 16, 0, 18, 0, 18, 17, 44, 35, 59, 60, 0, 34, 16, 17, 0, 0, 0, 0, 0…
$ availability_90                              <dbl> 14, 64, 45, 0, 47, 0, 48, 47, 74, 65, 89, 90, 0, 54, 35, 47, 0, 0, 0, 0, 3…
$ availability_365                             <dbl> 56, 236, 221, 0, 138, 0, 323, 276, 86, 245, 364, 365, 0, 292, 172, 223, 0,…
$ calendar_last_scraped                        <date> 2025-03-20, 2025-03-20, 2025-03-20, 2025-03-21, 2025-03-20, 2025-03-21, 2…
$ number_of_reviews                            <dbl> 84, 7, 23, 0, 6, 0, 2, 75, 236, 47, 0, 2, 0, 3, 17, 157, 0, 0, 0, 0, 19, 1…
$ number_of_reviews_ltm                        <dbl> 8, 0, 0, 0, 0, 0, 0, 4, 13, 2, 0, 0, 0, 1, 1, 36, 0, 0, 0, 0, 2, 1, 0, 1, …
$ number_of_reviews_l30d                       <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ availability_eoy                             <dbl> 14, 217, 182, 0, 138, 0, 245, 214, 86, 245, 286, 286, 0, 225, 172, 152, 0,…
$ number_of_reviews_ly                         <dbl> 7, 0, 0, 0, 0, 0, 1, 4, 13, 2, 0, 0, 0, 1, 2, 36, 0, 0, 0, 0, 2, 3, 0, 1, …
$ estimated_occupancy_l365d                    <dbl> 48, 0, 0, 0, 0, 0, 0, 24, 104, 12, 0, 0, 0, 8, 6, 216, 0, 0, 0, 0, 28, 6, …
$ estimated_revenue_l365d                      <dbl> 32352, 0, 0, NA, 0, NA, 0, 32640, 228800, 38232, 0, 0, NA, 312000, 9378, 1…
$ first_review                                 <date> 2013-05-31, 2013-01-06, 2010-06-15, NA, 2017-04-23, NA, 2023-01-03, 2012-…
$ last_review                                  <date> 2025-01-08, 2022-06-16, 2022-08-24, NA, 2023-03-29, NA, 2024-02-17, 2025-…
$ review_scores_rating                         <dbl> 4.81, 5.00, 4.36, NA, 5.00, NA, 5.00, 4.92, 4.77, 4.81, NA, 4.50, NA, 5.00…
$ review_scores_accuracy                       <dbl> 4.82, 4.86, 4.50, NA, 5.00, NA, 5.00, 4.96, 4.87, 4.91, NA, 4.00, NA, 5.00…
$ review_scores_cleanliness                    <dbl> 4.69, 4.86, 4.14, NA, 5.00, NA, 5.00, 4.88, 4.82, 4.83, NA, 4.00, NA, 5.00…
$ review_scores_checkin                        <dbl> 4.96, 4.86, 4.73, NA, 5.00, NA, 5.00, 4.97, 4.77, 4.98, NA, 4.50, NA, 5.00…
$ review_scores_communication                  <dbl> 4.95, 4.71, 4.77, NA, 5.00, NA, 5.00, 4.99, 4.80, 4.94, NA, 5.00, NA, 5.00…
$ review_scores_location                       <dbl> 4.77, 4.86, 4.82, NA, 5.00, NA, 4.50, 4.88, 4.74, 4.94, NA, 5.00, NA, 5.00…
$ review_scores_value                          <dbl> 4.80, 5.00, 4.41, NA, 5.00, NA, 5.00, 4.88, 4.83, 4.85, NA, 4.00, NA, 5.00…
$ license                                      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
$ instant_bookable                             <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
$ calculated_host_listings_count               <dbl> 1, 6, 1, 1, 1, 1, 2, 1, 1, 2, 6, 1, 1, 6, 3, 5, 1, 1, 1, 1, 1, 3, 2, 1, 2,…
$ calculated_host_listings_count_entire_homes  <dbl> 1, 1, 1, 0, 1, 0, 2, 1, 1, 2, 6, 1, 1, 6, 2, 5, 0, 0, 1, 0, 1, 3, 1, 1, 2,…
$ calculated_host_listings_count_private_rooms <dbl> 0, 5, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0,…
$ calculated_host_listings_count_shared_rooms  <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ reviews_per_month                            <dbl> 0.58, 0.05, 0.13, NA, 0.06, NA, 0.07, 0.47, 1.53, 0.34, NA, 0.01, NA, 0.03…
```

Wow! That is a lot of variables. But I found our `amenities` column. Let's take a look.

```R
listings_raw %>%
  head(5) %>%
  pull(amenities)
```

Ah it's an annoying string that is a list of strings.

```
[5] "[\"Portable fans\", \"32 inch HDTV\", \"Mountain view\", \"Refrigerator\", \"Oven\", \"Hot water\", \"Books and reading material\", \"Barbecue utensils\", \"Bathtub\", \"Wifi\", \"Self check-in\", \"Kitchen\", \"Cooking basics\", \"Clothing storage: closet and dresser\", \"First aid kit\", \"Hammock\", \"Bed linens\", \"Laundromat nearby\", \"Extra pillows and blankets\", \"Baking sheet\", \"Building staff\", \"Dishes and silverware\", \"Hair dryer\", \"Cleaning products\", \"Private patio or balcony\", \"Coffee maker: Nespresso\", \"Toaster\", \"Ceiling fan\", \"Dedicated workspace\", \"Free dryer \\u2013 In building\", \"Wine glasses\", \"Ethernet connection\", \"Private entrance\", \"BBQ grill\", \"Drying rack for clothing\", \"Iron\", \"Outdoor furniture\", \"Dishwasher\", \"Beach essentials\", \"Fire extinguisher\", \"Hangers\", \"Coffee\", \"Free street parking\", \"Luggage dropoff allowed\", \"Essentials\", \"Long term stays allowed\", \"Outdoor dining area\", \"Free washer \\u2013 In unit\", \"Body soap\", \"Room-darkening shades\", \"Gas stove\", \"Dining table\", \"Freezer\", \"Private backyard \\u2013 Fully fenced\", \"Central air conditioning\", \"Hot water kettle\", \"Microwave\", \"Blender\", \"Heating\", \"Free parking on premises\"]"
```

But before we do that, we need to get a list of all the types of amenities available.  First we filter for any empty list or missing data:

```R
listings_raw %>%
  select(amenities) %>%
  filter(amenities != "[]", !is.na(amenities))
```

Then we convert it to an R list using the `jsonliste::fromJSON`

```R
mutate(amenities = lapply(amenities, fromJSON))
```

Then we unnest and count. The unnest has two advantages above a simple unique call: it makes a unique list, but also shows us how frequent these are

```R
listings_raw %>%
  select(amenities) %>%
  filter(amenities != "[]", !is.na(amenities)) %>%
  mutate(amenities = lapply(amenities, fromJSON)) %>%
  unnest(amenities) %>%
  count(amenities, sort = TRUE)
```

```
# A tibble: 6,307 × 2
   amenities                 n
   <chr>                 <int>
 1 Wifi                  23200
 2 Kitchen               22959
 3 Hangers               19626
 4 Iron                  19170
 5 Hot water             19099
 6 Dishes and silverware 18658
 7 Essentials            18532
 8 Bed linens            17786
 9 Microwave             17706
10 Cooking basics        17602
# ℹ 6,297 more rows
```

Ah. Makes sense. Wifi is absolutely important. Wait... "6,297 more rows"... heh? Let me flip the order with a `arrange(desc(amenities))`:

```
# A tibble: 6,307 × 2
   amenities                                      n
   <chr>                                      <int>
 1 其他 gas stove                                 1
 2 Zanussi stainless steel oven                   1
 3 Zanussi stainless steel gas stove              1
 4 Yuppychef induction stove                      1
 5 Yuppie Chef induction stove                    1
 6 Yuppi chef induction stove                     1
 7 Yes 2 assorted  body soap                      1
 8 Yamaha system sound system with aux            1
 9 Yamaha sound system with aux                   4
10 Yamaha sound system with Bluetooth and aux     3
# ℹ 6,297 more rows
```

Clearly there isn't a multi picklist select option for the `amenities` you add... Let's have a look at the different types of wifi:

```R
amenities_freq %>%
  filter(str_detect(amenities, regex("wifi", ignore_case = TRUE)))
```

```txt
# A tibble: 298 × 2
   amenities               n
   <chr>               <int>
 1 Wifi                23200
 2 Pocket wifi           330
 3 Fast wifi – 52 Mbps    48
 4 Wifi – 48 Mbps         40
 5 Fast wifi – 51 Mbps    39
 6 Wifi – 47 Mbps         38
 7 Fast wifi – 50 Mbps    37
 8 Wifi – 31 Mbps         36
 9 Wifi – 36 Mbps         35
10 Wifi – 49 Mbps         33
# ℹ 288 more rows
```

Clearly we need to perform some sort of aggregation. Sounds like it's time for my good old friend `case_when`. My favorite `R` function. We can combine this with the `str_detect` and `regex` functions to perform a basic aggregation `mutate` step.

```R
amenities_freq %>%
  mutate(
    amenity_grouped = case_when(
      str_detect(amenities, regex("wifi|internet", ignore_case = TRUE)) ~ "Wifi",
      TRUE ~ amenities
    )
  ) %>%
  count(amenity_grouped, sort = FALSE)
```

We do have one risk with this method... There is a chance that we have an amenity called "TV with wifi connection", which will group it under WiFi.

But we need to start thinking about how we want to structure the final dataset! I want Something like this:

| Listing | Price | Wifi | Kitchen | Hangers | Iron | Number of Amenities |
| ------- | ----- | ---- | ------- | ------- | ---- | ------------------- |
| 1       | R2000 | 1    | 0       | 1       | 0    | 0                   |
| 2       | R3000 | 1    | 1       | 1       | 1    | 4                   |

I want to have a column per amenity, with a 0 or 1 indicating if this listing had the amenity or not, Price, which will be our target predictor (or something similar), and the number of amenities.

Ok let's circle back to our main pipe where we transformed the amenities to a JSON list:

```R
listings_raw %>%
  head(1000) %>%
  select(id, listing_url, amenities) %>%
  filter(amenities != "[]", !is.na(amenities)) %>%
  mutate(amenities = lapply(amenities, fromJSON)) %>%
  mutate(n_amenities = map_int(amenities, length))
```

We'll focus on the first 1000 for now... otherwise it's too slow to develop the pipe. I added a `mutate(n_amenities = map_int(amenities, length))` to the pipe to get the number of amenities.

Next is to aggregate the list of amenities from 6000+ unique values to a much smaller list:

```
mutate(amenities = map(amenities, ~ map_chr(.x, categorize_amenities)))
```

This will loop over the list (`map`) and apply a function called `categorize_amenities` to each value in the list (`.x`). `categorize_amenities` is that `case_when` function I mentioned:

```R
categorize_amenities <- function(amenity) {
  print(amenity)
  case_when(
    str_detect(amenity, regex("wifi|internet|ethernet", ignore_case = TRUE)) ~ "Internet",
    str_detect(amenity, regex("kitchen|oven|stove|refrigerator|fridge|freezer|blender|glasses|microwave|dinnerware|cooking|dishes and silverware|toaster|cleaning products|dishwasher|baking", ignore_case = TRUE)) ~ "Kitchen",
    str_detect(amenity, regex("hangers|iron|clothing|dryer|washer", ignore_case = TRUE)) ~ "Clothes",
    str_detect(amenity, regex("bed linens|pillows|blankets|hair dryer|mosquito net", ignore_case = TRUE)) ~ "Bedroom",
    str_detect(amenity, regex("hot water|shampoo|soap|bathtub|shower|hot tub|bidet", ignore_case = TRUE)) ~ "Bathroom",
    str_detect(amenity, regex("tv|hdtv|netflix|grill|barbecue|bbq|books|games|pool table|toys", ignore_case = TRUE)) ~ "Entertainment",
    str_detect(amenity, regex("beach|view|waterfront|access", ignore_case = TRUE)) ~ "Area",
    str_detect(amenity, regex("patio|balcony|fireplace|pool|backyard|fire pit|dining area|elevator|pets allowed", ignore_case = TRUE)) ~ "Building",
    str_detect(amenity, regex("parking", ignore_case = TRUE)) ~ "Parking",
    str_detect(amenity, regex("essentials", ignore_case = TRUE)) ~ "Essentials",
    str_detect(amenity, regex("workspace|table|sound system|piano|hammock|furniture|loungers|chair|exercise equipment", ignore_case = TRUE)) ~ "Furniture",
    str_detect(amenity, regex("heating|air conditioning|fans|fan|conditioner|heater", ignore_case = TRUE)) ~ "Air Conditioning",
    str_detect(amenity, regex("Long term stays allowed|greets|laundromat nearby|breakfast|gym|staff", ignore_case = TRUE)) ~ "Services",
    str_detect(amenity, regex("Fire extinguisher|First aid kit|alarm|safe|lockbox|lock|guards|fenced", ignore_case = TRUE)) ~ "Safety",
    str_detect(amenity, regex("Coffee", ignore_case = TRUE)) ~ "Coffee",
    TRUE ~ "Other"
  )
}
```

Now how on earth did I decide to make this list? It was quite manual. I opened the result of `amenities_freq` and wen through them one by one. I only considered the ones where the count is more than `400`. I then tried to group all the amenities into 15 categories:

1. Internet
2. Kitchen
3. Clothes
4. Bedroom
5. Bathroom
6. Entertainment
7. Area
8. Building
9. Parking
10. Essentials
11. Furniture
12. Air Conditioning
13. Services
14. Safety
15. Other

This is much better! Now the model will have less categories to worry about. Note how we have an "Other" category. This means the amenity was so unique that it was not in the regex list. But this will still come through in the `n_amenities` property.

Also note my `print(amenity)`. This is for me to make sure my script it still alive. It takes a really long time for this data cleaning step to run!

![airbnb-regex-working](/images/airbnb-regex-working.gif)

Awesome. Now for our predictor.  We can see the price is stored as strings "$674.00", "$1,818.00", "$621.00". Also, they're reporting in dollar, even though it's in rand!

First we remove the dollar:

```R
mutate(price = str_replace(price, "\\$", "")
```

Then we remove the thousands separator and cast to numeric

```R
mutate(price = as.numeric(str_replace(price, ",", "")))
```

Let's check:

```
  price_old price
  <chr>     <dbl>
1 $674.00     674
2 $1,818.00  1818
3 $621.00     621
4 $1,400.00  1400
5 $7,000.00  7000
6 $1,360.00  1360
7 $2,200.00  2200
8 $3,186.00  3186
```

Lastly, I want to remove Airbnb's marketing 101 strategy. All listings also have a minimum nights. See that "621"? Looks like a good deal? Well that is actually the price per night. All listings have a minimum stay:

```
  price_old price minimum_nights
  <chr>     <dbl>          <dbl>
1 $674.00     674              3
2 $1,818.00  1818              2
3 $621.00     621             30
4 $1,400.00  1400              1
5 $7,000.00  7000              5
6 $1,360.00  1360              2
7 $2,200.00  2200              4
8 $3,186.00  3186              2
```

Ah so if you go for that listing, you need to book it for 30 nights. So your total stay is actually R18, 630!

```
price_old price minimum_nights price_total_stay
  <chr>     <dbl>          <dbl>            <dbl>
1 $674.00     674              3             2022
2 $1,818.00  1818              2             3636
3 $621.00     621             30            18630
4 $1,400.00  1400              1             1400
5 $7,000.00  7000              5            35000
6 $1,360.00  1360              2             2720
7 $2,200.00  2200              4             8800
8 $3,186.00  3186              2             6372
```

Lastly, there is another bias we need to try to remove: the number of beds. More beds means that your listing is bigger. Bigger listing means a higher cost. We remove it by dividing the `price_total_stay` by the number of bedrooms:

```
  price minimum_nights bedrooms total_price_per_bedroom
  <dbl>          <dbl>    <dbl>                   <dbl>
1   674              3        1                   2022 
2  1818              2        1                   3636 
3   621             30        1                  18630 
4  1400              1        2                    700 
5  7000              5        3                  11667.
6  1360              2        1                   2720 
7  2200              4        2                   4400 
8  3186              2        3                   2124
```

So our predictor will be `total_price_per_bedroom`:

```R
mutate(
	total_price_per_bedroom = (price * minimum_nights) / bedrooms
)
```

Lastly, I'll also save the `listings_cleanded`, which contains ward information. We'll try to remove this bias later on!

The final cleaning pipeline will look something like this:

```R
listings_raw <- read_csv(file.path(DATA_RAW_DIR, "listings.csv.gz")) %>%
  as_tibble() %>%
  janitor::clean_names()


categorize_amenities <- function(amenity) {
  print(amenity)
  case_when(
    str_detect(amenity, regex("wifi|internet|ethernet", ignore_case = TRUE)) ~ "Internet",
    str_detect(amenity, regex("kitchen|oven|stove|refrigerator|fridge|freezer|blender|glasses|microwave|dinnerware|cooking|dishes and silverware|toaster|cleaning products|dishwasher|baking", ignore_case = TRUE)) ~ "Kitchen",
    str_detect(amenity, regex("hangers|iron|clothing|dryer|washer", ignore_case = TRUE)) ~ "Clothes",
    str_detect(amenity, regex("bed linens|pillows|blankets|hair dryer|mosquito net", ignore_case = TRUE)) ~ "Bedroom",
    str_detect(amenity, regex("hot water|shampoo|soap|bathtub|shower|hot tub|bidet", ignore_case = TRUE)) ~ "Bathroom",
    str_detect(amenity, regex("tv|hdtv|netflix|grill|barbecue|bbq|books|games|pool table|toys", ignore_case = TRUE)) ~ "Entertainment",
    str_detect(amenity, regex("beach|view|waterfront|access", ignore_case = TRUE)) ~ "Area",
    str_detect(amenity, regex("patio|balcony|fireplace|pool|backyard|fire pit|dining area|elevator|pets allowed", ignore_case = TRUE)) ~ "Building",
    str_detect(amenity, regex("parking", ignore_case = TRUE)) ~ "Parking",
    str_detect(amenity, regex("essentials", ignore_case = TRUE)) ~ "Essentials",
    str_detect(amenity, regex("workspace|table|sound system|piano|hammock|furniture|loungers|chair|exercise equipment", ignore_case = TRUE)) ~ "Furniture",
    str_detect(amenity, regex("heating|air conditioning|fans|fan|conditioner|heater", ignore_case = TRUE)) ~ "AirConditioning",
    str_detect(amenity, regex("Long term stays allowed|greets|laundromat nearby|breakfast|gym|staff", ignore_case = TRUE)) ~ "Services",
    str_detect(amenity, regex("Fire extinguisher|First aid kit|alarm|safe|lockbox|lock|guards|fenced", ignore_case = TRUE)) ~ "Safety",
    str_detect(amenity, regex("Coffee", ignore_case = TRUE)) ~ "Coffee",
    TRUE ~ "Other"
  )
}


listings_cleanded <- listings_raw %>%
  select(id, listing_url, amenities, price, minimum_nights, neighbourhood_cleansed, bedrooms) %>%
  filter(amenities != "[]", !is.na(amenities), !is.na(price)) %>%
  mutate(price = str_replace(price, "\\$", "")) %>%
  mutate(price = as.numeric(str_replace(price, ",", ""))) %>%
  filter( price < 5e5) %>%  # These listings are a joke!
  mutate(
    bedrooms = case_when(
      bedrooms == 0 ~ NA,
      TRUE ~ bedrooms
    )
  ) %>%
  mutate(
    total_price_per_bedroom = (price * minimum_nights) / bedrooms
  ) %>%
  mutate(amenities = lapply(amenities, fromJSON)) %>%
  mutate(n_amenities = map_int(amenities, length)) %>%
  mutate(amenities = map(amenities, ~ map_chr(.x, categorize_amenities))) %>%
  unnest(amenities) %>%
  distinct(id, listing_url, total_price_per_bedroom, n_amenities, amenities, neighbourhood_cleansed) %>%  # avoid duplicate amenities for a listing
  mutate(value = 1) %>%
  pivot_wider(
    names_from = amenities,
    values_from = value,
    values_fill = 0
  )

save_to_processed(listings_cleanded, "listings_cleanded")
```

```
$ id                      <dbl> 3191, 15077, 15480, 19384, 20263, 298622, 357793, 15007
$ listing_url             <chr> "https://www.airbnb.com/rooms/3191", "https://www.airbnb.com/rooms/15077", "https://www.airbnb.…
$ total_price_per_bedroom <dbl> 2022.00, 3636.00, 18630.00, 700.00, 11666.67, 2720.00, 4400.00, 2124.00
$ n_amenities             <int> 33, 56, 38, 60, 68, 75, 49, 68
$ neighbourhood_cleansed  <chr> "Ward 57", "Ward 4", "Ward 115", "Ward 77", "Ward 64", "Ward 61", "Ward 115", "Ward 23"
$ Kitchen                 <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Bathroom                <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Internet                <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Safety                  <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Entertainment           <dbl> 1, 1, 0, 1, 1, 1, 1, 1
$ Services                <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Building                <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ AirConditioning         <dbl> 1, 1, 1, 1, 1, 0, 1, 1
$ Other                   <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Clothes                 <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Essentials              <dbl> 1, 0, 1, 1, 1, 1, 1, 1
$ Coffee                  <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Parking                 <dbl> 1, 1, 1, 1, 1, 1, 1, 1
$ Furniture               <dbl> 0, 1, 1, 1, 1, 1, 0, 1
$ Bedroom                 <dbl> 0, 1, 1, 1, 1, 1, 1, 1
$ Area                    <dbl> 0, 1, 0, 1, 1, 1, 1, 1
```

You will not BELIEVE how long it took to do this for 20 K rows where each one has a couple of amenities per row

## Model Strategy

So... remember when I mentioned that I want to remove the location bias? I'm no expert, but I suspect that I can create a model per ward and then just combine all the feature importance results per ward to get an average.

I want to use the `purr::walk()` method for this one. It's useful for doing the same steps for different values in a categorical column:

```R
listings <- load_from_processed("listings_cleanded")

unique_neighbourhoods <- listings %>% 
  distinct(neighbourhood_cleansed) %>% 
  pull()


walk(unique_neighbourhoods, function(neighbourhood) {
  neighbourhood_data <- listings %>% 
    filter(neighbourhood_cleansed == neighbourhood)
  
  print(neighbourhood)
  
})
```

This loop will be useful later, but for now, let's set the neighbourhood and focus on developing a single model... before we start looping like crazy!

