#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

mode='default'

wm=1
. /home/data_${1}/cabal_war/${mode}/warmap${wm}.ini
sed -i \
-e "s/^BattleFieldTimeAttackSec=.*/BattleFieldTimeAttackSec=$TimeAttackSec/g" \
-e "s/^Reward_Standard=.*/Reward_Standard=$Points/g" \
-e "s/^Add_Reward_Item_Index=.*/Add_Reward_Item_Index=$ItemID/g" \
-e "s/^Add_Reward_Item_Option=.*/Add_Reward_Item_Option=$ItemOPT/g" \
-e "s/^Add_Reward_Item_Duration=.*/Add_Reward_Item_Duration=$ItemDUR/g" \
-e "s/^FixedWarExpNationMultiple=.*/FixedWarExpNationMultiple=$WexpCoef/g" \
/home/data_${1}/cabal/Data/Data_War/War_Default_${wm}_*

wm=2
. /home/data_${1}/cabal_war/${mode}/warmap${wm}.ini
sed -i \
-e "s/^BattleFieldTimeAttackSec=.*/BattleFieldTimeAttackSec=$TimeAttackSec/g" \
-e "s/^Reward_Standard=.*/Reward_Standard=$Points/g" \
-e "s/^Add_Reward_Item_Index=.*/Add_Reward_Item_Index=$ItemID/g" \
-e "s/^Add_Reward_Item_Option=.*/Add_Reward_Item_Option=$ItemOPT/g" \
-e "s/^Add_Reward_Item_Duration=.*/Add_Reward_Item_Duration=$ItemDUR/g" \
-e "s/^FixedWarExpNationMultiple=.*/FixedWarExpNationMultiple=$WexpCoef/g" \
/home/data_${1}/cabal/Data/Data_War/War_Default_${wm}_*

wm=3
. /home/data_${1}/cabal_war/${mode}/warmap${wm}.ini
sed -i \
-e "s/^BattleFieldTimeAttackSec=.*/BattleFieldTimeAttackSec=$TimeAttackSec/g" \
-e "s/^Reward_Standard=.*/Reward_Standard=$Points/g" \
-e "s/^Add_Reward_Item_Index=.*/Add_Reward_Item_Index=$ItemID/g" \
-e "s/^Add_Reward_Item_Option=.*/Add_Reward_Item_Option=$ItemOPT/g" \
-e "s/^Add_Reward_Item_Duration=.*/Add_Reward_Item_Duration=$ItemDUR/g" \
-e "s/^FixedWarExpNationMultiple=.*/FixedWarExpNationMultiple=$WexpCoef/g" \
/home/data_${1}/cabal/Data/Data_War/War_Default_${wm}_*

wm=4
. /home/data_${1}/cabal_war/${mode}/warmap${wm}.ini
sed -i \
-e "s/^BattleFieldTimeAttackSec=.*/BattleFieldTimeAttackSec=$TimeAttackSec/g" \
-e "s/^Reward_Standard=.*/Reward_Standard=$Points/g" \
-e "s/^Add_Reward_Item_Index=.*/Add_Reward_Item_Index=$ItemID/g" \
-e "s/^Add_Reward_Item_Option=.*/Add_Reward_Item_Option=$ItemOPT/g" \
-e "s/^Add_Reward_Item_Duration=.*/Add_Reward_Item_Duration=$ItemDUR/g" \
-e "s/^FixedWarExpNationMultiple=.*/FixedWarExpNationMultiple=$WexpCoef/g" \
/home/data_${1}/cabal/Data/Data_War/War_Default_${wm}_*

wm=5
. /home/data_${1}/cabal_war/${mode}/warmap${wm}.ini
sed -i \
-e "s/^BattleFieldTimeAttackSec=.*/BattleFieldTimeAttackSec=$TimeAttackSec/g" \
-e "s/^Reward_Standard=.*/Reward_Standard=$Points/g" \
-e "s/^Add_Reward_Item_Index=.*/Add_Reward_Item_Index=$ItemID/g" \
-e "s/^Add_Reward_Item_Option=.*/Add_Reward_Item_Option=$ItemOPT/g" \
-e "s/^Add_Reward_Item_Duration=.*/Add_Reward_Item_Duration=$ItemDUR/g" \
-e "s/^FixedWarExpNationMultiple=.*/FixedWarExpNationMultiple=$WexpCoef/g" \
/home/data_${1}/cabal/Data/Data_War/War_Default_${wm}_*
