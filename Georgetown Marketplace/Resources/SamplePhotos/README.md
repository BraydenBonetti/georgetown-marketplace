# Sample listing photos

Real JPEGs for the sample Marketplace listings. `SampleData` loads
`sample_listings.json` (109 listings) and attaches photos via
`bundledPhotos` by filename. If a file is missing, that listing falls
back to the gradient/symbol placeholder.

## Naming

| Pattern | Example |
|---|---|
| Original set | `sample-desk.jpg`, `sample-textbook.jpg`, … |
| Expanded set | `sample-l10.jpg` … `sample-l109.jpg` |

Textbooks use Open Library cover art with exact titles/ISBNs in the
listing copy. Other items use Unsplash product/lifestyle photos.

Rebuild / refresh with:

```bash
python3 scripts/build_sample_catalog.py
```

Photos are roughly ≤1000px on the long edge.
