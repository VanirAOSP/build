#
# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This is a build configuration that just contains a list of languages.
# It helps in situations where languages must come first in the list,
# mostly because screen densities interfere with the list of locales and
# the system misbehaves when a density is the first locale.

# Those are all the locales that have translations and are displayable
# by TextView in this branch.
PRODUCT_LOCALES := en_US cs_CZ da_DK de_AT de_CH de_DE de_LI el_GR en_AU en_CA en_GB en_NZ en_SG es_ES fr_CA fr_CH fr_BE fr_FR it_CH it_IT ja_JP ko_KR nb_NO nl_BE nl_NL pl_PL pt_PT ru_RU sv_SE tr_TR zh_CN zh_HK zh_TW am_ET hi_IN
