/* *************************************************************
***Smart Contract for save deals between worker & customer******
***blockchain-concept.com***********ru.blockchain-concept.com***
************************************************************* */
pragma solidity ^0.4.0;
contract SAFE_PAYMENT{
//-----------------data section-------------------------------------------------
    address owner;
    address secondOwner;
    struct order{
        uint orderID;                       // customer's internal order id
        address customerAddress;            // main address of the customer
        uint invoice;                       // payment for work
        uint ownerPaid;                     // owner payed value (insuranse payment)
        uint customerPaid;                  // payed value (must be more then ownerPaid)
        string caption;                     // order's title from contract owner
        string description;                 // order's description from contract owner
        string comment;                     // comment from customer
        uint paimentDate;                   // last payment date
        bool lockOwnerMoneyBack;            // unlock (0 -unlock; 1 - lock) ownerPaid money to contract owner 
        bool lockCustomerMoneyBack;         // unlock (0 -unlock; 1 - lock) money back to customer
        bool lockMoney;                     // unlock (0 -unlock; 1 - lock) money from contract to contract owner
        uint orderState;                    // 0-new, 1-payed 2-in progress, 3-ready 4-finished 7-owner took money (if >=4 it is impossible for customer to lock money by paying) 5-canceled
        address secondAddress;              // additional address for customer
        address resultContract;             // work result smart contract address for deleting controll owner (set only customer's addresses to owners)
        string resultContractABI;           // ABI interface for work result smart contract 
        uint stateChangeDate;               // last state change date
    }
    order[] orders;
    mapping (address => uint) paymentsNoOrder;      // array of all customer's payments without order's links
    mapping (address => uint) customerOrdersNum;    // array of customer's orders number
    mapping (address => uint) freeBalances;         // array of users deposit. Everyone can pay for this contract address and then take their money back
    uint allCustomersNum;                           // customers amount
    uint public maxAllowedOpenOrdersPerCustomer;    // limit from spam orders creating    

//-----------------modificators-------------------------------------------------
// for owner check
    modifier _isOwner{
        require (msg.sender == owner || msg.sender == secondOwner);
        _;
    }
//-----------------implementation-----------------------------------------------
//------------------------------------------------------------------------------
/*-----------------------common part------------------------*/
//constructor
function SAFE_PAYMENT(){
    owner = msg.sender;
    secondOwner = msg.sender;
    allCustomersNum = 0;
    maxAllowedOpenOrdersPerCustomer = 10;
}
//for payments receiving 
function () payable {freeBalances[msg.sender]+=msg.value;}
//check order's access permission for owner and customer by its id
function isOwnCust(uint _orderID) private returns(bool){
    if (msg.sender == owner || msg.sender == secondOwner || msg.sender == orders[_orderID].customerAddress || msg.sender == orders[_orderID].secondAddress)
        return true;
    else
        return false;
}
//check order's access permission for its customer by order id
function isCustomer(uint _orderID) private returns(bool){
    if (msg.sender == orders[_orderID].customerAddress || msg.sender == orders[_orderID].secondAddress)
        return true;
    else
        return false;
}
//check for prepared wor customer contract exist
function CheckContractExist(address _resultContract, string _resultContractABI) private returns(bool){
//реализовать проверку существования контракта по адресу, например, через функцию обратного вызова    
}

function RemoveResContractOwners(address _resultContract, string _resultContractABI) private returns(bool){
//реализовать удаление всех владельцев кроме адресов заказчика из разработанного контракта    
}
// send money from Free balanses to order/ 0-error(no money) 1-ok(customer order deposit) 2-ok(owner insuranse payment) 3-error(invalid order num) 
function SendEtherToOrder(uint _orderID, uint _amount) private returns(uint _res){
    _res=0;
    if(freeBalances[msg.sender] >= _amount){
        _res=3;
        //contract owner can't create contract to work with himself
        if(msg.sender == owner || msg.sender==secondOwner){
            freeBalances[msg.sender] -= _amount;
            orders[_orderID].ownerPaid +=_amount;
            _res=1;
        }
        if(isOwnCust(_orderID) == true){
            freeBalances[msg.sender] -= _amount;
            orders[_orderID].customerPaid +=_amount;
            _res=2;
        }
    }
    return _res;
}


/*-----------------------for customer------------------------*/
// 1. create order
function CreateOrder(string _caption, string _description, string _comment) returns(uint _res){
    uint globalOrderID;
    if (customerOrdersNum[msg.sender] >=maxAllowedOpenOrdersPerCustomer){
        _res=0;
        return _res;
    }else{
        globalOrderID = orders.length;
        if(customerOrdersNum[msg.sender]==0){
            allCustomersNum +=1;                                                // customers amount
        }
        orders.length+=1;        
        orders[globalOrderID].orderID = customerOrdersNum[msg.sender];          // customer's internal order id
        customerOrdersNum[msg.sender] +=1;                                      // customer's orders number
        orders[globalOrderID].customerAddress = msg.sender;                     // additional address for customer
        orders[globalOrderID].secondAddress = msg.sender;                       // work result smart contract address for deleting controll owner (set only customer's addresses to owners)
        orders[globalOrderID].caption=_caption;                                 // order's title from contract owner
        orders[globalOrderID].description=_description;                         // order's description from contract owner
        orders[globalOrderID].comment=_comment;                                 // comment from customer
        orders[globalOrderID].orderState = 0;                                   // 0-new, 1-payed 2-in progress, 3-ready 4-finished (if >=4 it is impossible for customer to lock money by paying) 5-canceled
        orders[globalOrderID].stateChangeDate=now;                              // last state change date
        orders[globalOrderID].lockOwnerMoneyBack = false;                       // unlock(=0) ownerPaid money to contract owner 
        orders[globalOrderID].lockCustomerMoneyBack = false;                    // unlock(=0) money back to customer
        orders[globalOrderID].lockMoney = false;                                // unlock(=0) money from contract to contract owner    
       _res = globalOrderID;
       return _res;
    }
}
function SetSecondAddress(uint _orderID, address _secondAddress)returns(bool){if(isCustomer(_orderID)==true){orders[_orderID].secondAddress = _secondAddress; return true;}} // 1. Customer can change second manager address for his order
function SetlockOwnerMoneyBack(uint _orderID) returns(bool){if(isCustomer(_orderID)==true){orders[_orderID].lockOwnerMoneyBack = false;return true;}} // 1. unlock security deposit for contract owner
function UnlockMoney(uint _orderID) returns(bool){if(isCustomer(_orderID)==true){orders[_orderID].lockMoney = false;orders[_orderID].lockOwnerMoneyBack = false;if(RemoveResContractOwners(orders[_orderID].resultContract, orders[_orderID].resultContractABI) == true){orders[_orderID].orderState = 4;return true;}}}// 1. unlock payment for work for contract owner
function UnlockOwnerPrePaidMoney(uint _orderID) returns(bool){if(isCustomer(_orderID)==true){orders[_orderID].lockOwnerMoneyBack = false;}}// 1. unlock owner security payment for work for contract owner
function MakePayment(uint _orderID, uint _value) returns(bool){if(isCustomer(_orderID)==true){if(SendEtherToOrder(_orderID, _value)==1){if (orders[_orderID].customerPaid > orders[_orderID].invoice){LockMoney(_orderID);}return true;}}}// Make Payment for future work. That is possible to pay as many times, as it is need. Auto lock Money after ncreasing invoice.
function LockMoney(uint _orderID) returns(bool){if(isCustomer(_orderID)==true){require(orders[_orderID].customerPaid >= orders[_orderID].invoice && orders[_orderID].invoice > 0);orders[_orderID].lockMoney = true;orders[_orderID].lockOwnerMoneyBack = true;orders[_orderID].lockCustomerMoneyBack = true;orders[_orderID].orderState = 1;return true;}}// Customer must paid value equal or more then it was set in invoice by owner
// Customer can take money back untill the order is not in work
function CustomerMoneyBack(uint _orderID) returns(bool){
    uint valueForPaid;
    if(isCustomer(_orderID)==true){
        require (orders[_orderID].lockCustomerMoneyBack == false);
        require (orders[_orderID].customerPaid > 0);
        valueForPaid = orders[_orderID].customerPaid;
        orders[_orderID].customerPaid = 0;
//превести все внесённые деньги ( valueForPaid) по заказу на главный адрес заказчика
        return true;
    }
}
function CustomerMoneyBackSecondAddress(uint _orderID) returns(bool){
    uint valueForPaid;
    if(isCustomer(_orderID)==true){
        require (orders[_orderID].lockCustomerMoneyBack == false);
        require (orders[_orderID].customerPaid > 0);
        valueForPaid = orders[_orderID].customerPaid;
        orders[_orderID].lockOwnerMoneyBack = false;
        orders[_orderID].customerPaid = 0;
//превести все внесённые деньги ( valueForPaid) по заказу на дополнительный адрес заказчика
        return true;
    }
}


/*-----------------------for customer AND owner--------------*/
function SetOrderComment(uint _orderID, string _comment) returns(bool){if (isOwnCust(_orderID) == true){orders[_orderID].comment = _comment;return true;}}// 1. change order's comment
function getInvoice(uint _orderID) constant returns (uint){if (isOwnCust(_orderID) == true){return orders[_orderID].invoice;}}
function getOwnerPaid(uint _orderID) constant returns (uint){if (isOwnCust(_orderID) == true){return orders[_orderID].ownerPaid;}}
function getCustomerPaid(uint _orderID) constant returns (uint){if (isOwnCust(_orderID) == true){return orders[_orderID].customerPaid;}}
function getCaption(uint _orderID) constant returns (string){if (isOwnCust(_orderID) == true){return orders[_orderID].caption;}}
function getDescription(uint _orderID) constant returns (string){if (isOwnCust(_orderID) == true){return orders[_orderID].description;}}
function getComment(uint _orderID) constant returns (string){if (isOwnCust(_orderID) == true){return orders[_orderID].comment;}}
function getPaimentDate(uint _orderID) constant returns (uint){if (isOwnCust(_orderID) == true){return orders[_orderID].paimentDate;}}
function getLockOwnerMoneyBack(uint _orderID) constant returns (bool){if (isOwnCust(_orderID) == true){return orders[_orderID].lockOwnerMoneyBack;}}
function getLockCustomerMoneyBack(uint _orderID) constant returns (bool){if (isOwnCust(_orderID) == true){return orders[_orderID].lockCustomerMoneyBack;}}
function getOrderState(uint _orderID) constant returns (uint){if (isOwnCust(_orderID) == true){return orders[_orderID].orderState;}}
function getSecondAddress(uint _orderID) constant returns (address){if (isOwnCust(_orderID) == true){return orders[_orderID].secondAddress;}}
function getResultContract(uint _orderID) constant returns (address){if (isOwnCust(_orderID) == true){return orders[_orderID].resultContract;}}
function getResultContractABI(uint _orderID) constant returns (string){if (isOwnCust(_orderID) == true){return orders[_orderID].resultContractABI;}}
function getStateChangeDate(uint _orderID) constant returns (uint){if (isOwnCust(_orderID) == true){return orders[_orderID].stateChangeDate;}}
function GetFreeBalances(address _member) returns(uint){if(msg.sender==_member || msg.sender==owner || msg.sender==secondOwner){return freeBalances[msg.sender];}}//everyone can red his own free balanse (and owner)


/*-----------------------for owner---------------------------*/
function UploadWork(uint _orderID, address _resultContract, string _resultContractABI) _isOwner returns(bool){
    if (CheckContractExist(_resultContract, _resultContractABI) == true 
    && orders[_orderID].customerPaid >= orders[_orderID].invoice 
    && orders[_orderID].invoice > 0
    && orders[_orderID].orderState < 4){
        orders[_orderID].orderState = 3;                                // 0-new, 1-payed 2-in progress, 3-ready 4-finished (if >=4 it is impossible for customer to lock money by paying) 5-canceled
        orders[_orderID].resultContract = _resultContract;              // work result smart contract address for deleting controll owner (set only customer's addresses to owners)
        orders[_orderID].resultContractABI = _resultContractABI;        // ABI interface for work result smart contract 
        orders[_orderID].stateChangeDate = now;                         // last state change date
        return true;
    }
}
function SetUploadWorkAddress(uint _orderID, address _resultContract, string _resultContractABI) _isOwner returns(bool){orders[_orderID].resultContract = _resultContract;orders[_orderID].resultContractABI = _resultContractABI;}//Write address and ABI for work result main smart contract
function SetSecondOwner(address _secondOwner) _isOwner returns(bool){secondOwner = _secondOwner;return true;}
function GetMaxOrderID() constant _isOwner returns(uint){return orders.length;} // reading orders amount (and last order number)
function GetMaxCustomerOrder(address _customer) constant _isOwner returns(uint){return customerOrdersNum[_customer];} // reading customer orders amount
function GetAllCustomersNum() constant _isOwner returns(uint){return allCustomersNum;} // reading all customers amount



/*-----------------------for owner(work with money)----------*/
// 1a. set invoice
function SetInvoice(uint _orderID, uint _invoice) _isOwner returns(bool){
    require (orders[_orderID].orderState == 0);
    orders[_orderID].invoice = _invoice;
    return true;
}
// 1b. make security deposit
function SecurityDeposit(uint _orderID, uint _value) _isOwner returns(bool){require(orders[_orderID].orderState == 0);if(SendEtherToOrder(_orderID, _value)==2){return true;}}
//7. withdraw all money from order o owner
function WithdrowOrderMoneyForOwner(uint _orderID) _isOwner returns(bool){
    require (orders[_orderID].lockMoney == false);
//превести все деньги по заказу на счёт owner
     orders[_orderID].ownerPaid = 0;
     orders[_orderID].customerPaid = 0;
     orders[_orderID].orderState = 4;
    return true;
}
//7. withdraw all money from order o second owner address
function WithdrowOrderMoneyForSecondOwner(uint _orderID) _isOwner returns(bool){
    require (orders[_orderID].lockMoney == false);
//превести все деньги по заказу на счёт secondOwner
     orders[_orderID].ownerPaid = 0;
     orders[_orderID].customerPaid = 0;
     orders[_orderID].orderState = 4;
    return true;
}
//7а. withdraw only SecurityDeposit money from order o owner
function WithdrowOwnerPaidForOwner(uint _orderID) _isOwner returns(bool){
    require (orders[_orderID].lockOwnerMoneyBack == false);
//превести только залоговые деньги по заказу на счёт owner
     orders[_orderID].ownerPaid = 0;
    return true;
}
//7а. withdraw only SecurityDeposit money from order o second owner address
function WithdrowOwnerPaidForSecondOwner(uint _orderID) _isOwner returns(bool){
    require (orders[_orderID].lockOwnerMoneyBack == false);
//превести только залоговые деньги по заказу на счёт secondOwner
     orders[_orderID].ownerPaid = 0;
    return true;
}












  
  
//for paying
function SendEtherToOwner(uint256 _amount) _isOwner private returns(bool){
    //owner.transfer(_amount); - передать на адрес владельца
}

}

//get+ paid   uint customerPaid;                  // payed value (must be more then ownerPaid)
//get+ set+-  bool lockMoney;                     // unlock (0 -unlock; 1 - lock) money from contract to contract owner
/*
виды платежей:
1. заказчик заказа забираетсвои деньги
    если разрешено
    сумма не больше внесённой, забирается целиком
    статус не оплачено
    сумму на балансе заказчика по заказу обнулить
    органичения для вывода залогового депозита для меня нужно снять
2. Я забираю залоговый депозит
    если разрешено
    сумму на балансе залога по работе обнулить
    сумма не больше внесённой, забирается целиком
3. я забираю всю сумму
    если разрешено
    сумма не больше внесённой, забирается целиком
    суммы по балансам обнулить
    статус 7
*/

/*
основное:
1.+ заказчик создаёт заказ и вносит комментарий к заказу. Задаёт резервный адрес аккаунта для управления заказом. Получает id заказа и сообщает мне. Ограничить от злоупотребления пустыми заказами.
-a.+ я выставляю счёт 
-b.+- я ложу свои деньги (опционно) в адрес работы (пока я ещё могу их снять)
-c. я корректирую параметры (кроме адресов и блокировок) существующего заказа, при условии что заказчик ещё не внёс деньги
2.+- заказчик ложит и докладывать деньги (в сумме обязательно больше чем в инвойсе), чем блокирует всю сумму (ото всех), отмеченную на заказываемой работе и ряд её полей
3.+- я выполняю работу и выгружаю контракт в сеть, указывая его адрес в ResultContract и статус = 3-ready
4.+- заказчик разблокирует деньги, автоматически удаляя все адреса владельцев кроме 2х своих из списка в рабочем контракте. контракт исполнен и не может дополняться деньгами (статус = 4-finished)
дополнительно:

5. я могу разблокировать сумму заказчика(статус = 5-canceled), после чего он сможет снять (все) свои деньги, автоматически разблокировав мои деньги (как только его денег станет меньше чем моих). Заказ уходит в историю.
6.+ я и только я могу любое количество раз менять: resultContract и resultContractABI;  
7.+- я могу снять деньги (свои или свои и оплату работы), если они разблокированны заказчиком (только сумму по конкретному заказу, уменьшив эту сумму в поле заказа)
-a.+- я могу снять залоговый депозит если разрешено
8.+- заказчик может снять свои деньги, если я их разблокировал, чем снимает блокировку с моих денег
9.+ всегда можно прочитать состояние всех параметров своего заказа
10.+ Я могу прочитать все параметры любых заказов
11.+ Я задаю дополнительный адрес для управления контрактом
12.+ Заказчик может разблокировать как мой залог, так и всю оплату по заказу для меня.
13.+ получение максимального номера заказа заказчика
14. добавить безопастные платежи
15. Заказчик не должен иметь возможность просто так заблокировать мне деньги, поскольку есть функция разблокировки со снятием защиты с результата работы. Т.е. чтобы он не снял защиту и не заблокировал мне потом деньги.
*/