# LRFetchedResultSet - auto-updating Core Data fetch results

Last night, I tweeted this:

<blockquote class="twitter-tweet"><p>Wouldn’t it be nice if instead of returning an array of objects from a fetch, Core Data returned some kind of auto updating fetch result?</p>&mdash; Luke Redpath (@lukeredpath) <a href="https://twitter.com/lukeredpath/status/277934596811804673" data-datetime="2012-12-10T00:35:46+00:00">December 10, 2012</a></blockquote>
<script src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

This is my attempt to satisfy that need.

## Getting started

There's nothing fancy here - you'll want to clone the submodules so you can run the tests. It's just one file at the moment.

A category on `NSManagedObjectContext` provides the `LR_executeFetchRequestAndReturnResultSet:error:`, which executes the fetch request and returns the resulting objects wrapped in an instance of `LRFetchedResultSet`. See the header file for more information.

You can observe changes to the result set by setting a change block. Changes will only be observed if this block is set.

```objc
NSFetchRequest *request = ...;

LRFetchedResultSet *results = [self.managedObjectContext LR_executeFetchRequestAndReturnResultSet:request error:nil];

if (results == nil) {
  // handle error
}
else {
  [results notifyChangesUsingBlock:^(NSDictionary *changes) {
    // changes contains inserted, updated and deleted objects
  }];
}
```

## Isn't this the same thing as NSFetchedResultsController?

Sort of - but not quite. For a start, NSFetchedResultsController is only available on iOS and it is specifically designed to work with UITableView data sources. It speaks in the domain of rows and sections, whereas this is more generic. You get your results, you can observe any changes to those results.

## License

All code is licensed under the MIT license. See the LICENSE file for more details.
