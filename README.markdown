WindowShopper
=============

Predict where a shopper is likely to go and what he's likely to buy
next.

Description
-----------

Given a set of previously visited locations, and actions (namely, item _gx_ has
been bought at location _ly_), WindowShopper tries to predict where the
shopper is likely to go next, and what he is likely to buy.

This library is based on the [In-store shopping activity
modeling based on dynamic bayesian networks](http://papers.ssrn.com/sol3/papers.cfm?abstract_id=1719317)
paper by _Ping Yan_ and _Daniel D. Zeng_, but implemented with a simple
dynamic naive bayesian network.

Warning: assumes that all features are independent. Quick and dirty code.
Non-optimized. Mostly untested. It probably doesn't work at all.
You've been warned. Carry on.

What is it useful for?
----------------------

It can be super useful if you own a store that has caddies equiped with
RFID chips. Plus all it takes to know who bought what and where.

For the rest of us, it can be useful for an online store, in order to
display a product that a customer might be interested in, even before
he reaches the page for this item's category.

Because just displaying the "most popular items for this category" is
boring, and something to complement the traditional recommendation
system can be cool.

What, no persistence? That's lame
---------------------------------

It is. But a naive bayesian network is compact, and easy to persist and
update. The way the network is currently stored in memory makes it
easy to use a key/value store instead.
If you are actually planning to use that code, drop me a line and I'll add
persistence.

Usage
-----

    require "windowshopper"
    
    shop = WindowShopper.store("Family Mart")
    
    shopper1 = shop.new_shopper
    shopper1.move_to(1)
    shopper1.move_to(2)
    shopper1.buy("fish")
    shopper1.move_to(3)
    shopper1.move_to(4)
    shopper1.buy("apple")
    
    shopper2 = shop.new_shopper
    shopper2.move_to(1)
    shopper2.move_to(2)
    shopper2.buy("fish")
    shopper2.move_to(3)
    
    puts shopper2.predict # {:locations=>[4], :goals=>["apple"]}

