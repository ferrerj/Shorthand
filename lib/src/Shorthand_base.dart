library Shorthand_base;

import 'dart:core';
import 'dart:io';
import 'dart:mirrors';
import 'dart:async';
import 'package:sqljocky5/sqljocky.dart';
import 'package:options_file/options_file.dart';

part 'InternalRules.dart';
part 'RuleBase.dart';
part 'DataRule.dart';
part 'ExternalRules.dart';

// Used to generate maps for use in the MapServer from an object based upon
// the rules provided.
class Shorthand {
  Map generatedMap;
  String currentRoute;

  // start generating off the bat by passing object and using base rules
  Shorthand({var object, String this.currentRoute}) {
    if (currentRoute == null) {
      currentRoute = "";
    }
    if (object != null) {
      generatedMap = objectToMap(object);
    }
  }

  objectToMap(var obj) {
    // used to get route metadata variables
    // flag for string to be turned into a function to be returned
    DataAggregate globals = new DataAggregate();
    InstanceMirror im = reflect(obj);
    ClassMirror cm = im.type;
    cm.metadata.forEach((metadata) {
      if (metadata.reflectee is GlobalDataRule) {
        globals.addToAggregate({metadata.reflectee.nameOfTheSymbol(metadata.type.simpleName): metadata.reflectee});
      }
    });
    List ll = cm.declarations.keys.toList();
    ll.remove(ll.last);
    Map m = new Map();
    // iterate over all members of the object
    for (Symbol x in ll) {
      String objectMemberName =
          x.toString().substring(8, x.toString().length - 2);
      // stores external/data rules to be iterated over later
      DataAggregate da = new DataAggregate();
      ExternalRuleAggregate era = new ExternalRuleAggregate();
      // need to add this here, takes some work out of the annotating
      da.addToAggregate(
          {"URLData": new RoutingInfo("${currentRoute}/${objectMemberName}")});
      // process the data
      for (InstanceMirror annotation in cm.declarations[x].metadata) {
        if (annotation.reflectee is RuleBase) {
          if (annotation.reflectee is MapRule) {
            MapRule mr = annotation.reflectee;
            da.addToAggregate(globals.aggregate);
            if(im.getField(x).reflectee is Function){
              // it is a method, will pass method mirror instead
              m.addAll(
                  mr.executeRule(objectMemberName, new EndPointHelperObject(cm.instanceMembers[x].parameters, im, x, da )));
              if(MapRule.dataRules!={}){
                  da.addToAggregate(MapRule.dataRules);
                  mr.clearDataRules();
              }
            } else {
              // it is a string or some other special data type,
              // just pass the object, they'll know what to do
              m.addAll(
                  mr.executeRule(objectMemberName, im.getField(x).reflectee, da));
            }
          } else if (annotation.reflectee is DataRule) {
            da.addToAggregate(
                {annotation.reflectee.nameOfTheSymbol(annotation.type.simpleName): annotation.reflectee});
          } else if (annotation.reflectee is ExternalRule) {
            era.addToAggregate(
                {annotation.reflectee.nameOfTheSymbol(annotation.type.simpleName): annotation.reflectee});
          }
        }
      }
      da.addToAggregate(globals.aggregate);
      if (era.aggregate != null) {
        era.aggregate.values.forEach((rule) {
          //print(rule.processTemplate(da));
          rule.processTemplate(da);
        });
      }
    }
    return m;
  }
}
